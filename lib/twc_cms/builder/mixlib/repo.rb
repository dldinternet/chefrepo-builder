module TWC_CMS
	module Builder

		# ---------------------------------------------------------------------------------------------------------------
		def getS3Bucket()
			unless @s3
				@s3 = AWS::S3.new(
					:access_key_id      => ENV['AWS_ACCESS_KEY_ID'],
					:secret_access_key  => ENV['AWS_SECRET_ACCESS_KEY'])
			end
			unless @s3_bucket
				@s3_bucket = @s3.buckets[ENV['AWS_S3_BUCKET']]
			end
			@s3_bucket
		end

		# ---------------------------------------------------------------------------------------------------------------
		def uploadToS3(artifacts)
			bucket = getS3Bucket()
			artifacts.each{|art|
				# makes no request, returns an AWS::S3::S3Object
				s3_obj = bucket.objects[art[:key]]
				if s3_obj.exists?
					@logger.info "s3://#{ENV['AWS_S3_BUCKET']}/#{art[:key]} exists"
					if art[:data].has_key?(:file)
						md5 = Digest::MD5.file(art[:data][:file]).hexdigest
					else
						#noinspection RubyArgCount
						md5 = Digest::MD5.hexdigest(art[:data][:data])
					end
					unless s3_obj.etag == md5
						@logger.info "s3://#{ENV['AWS_S3_BUCKET']}/#{art[:key]} is different from our #{art[:key]}(#{s3_obj.etag} <=> #{md5})"
						return 1
					end
				else
					@logger.info "Upload new s3://#{ENV['AWS_S3_BUCKET']}/#{art[:key]}"
					# Get size before upload changes our object
					if art[:data].has_key?(:file)
						size = File.size(art[:data][:file])
					else
						size = art[:data][:data].length
					end
					s3_obj.write(art[:data])
					if art.has_key?(:public_url)
						@vars[art[:public_url]] = s3_obj.public_url
					end
					if art.has_key?(:read_url)
						@vars[art[:read_url]]   = s3_obj.url_for(:read) if art.has_key?(:read_url)
					end
					@logger.info "#{art[:label]}: #{@vars[art[:public_url]]}" if art.has_key?(:public_url)
					if size > 16 * 1024 * 1024
						if size < 5 * 1024 * 1024 * 1000
							@logger.debug "#{art[:label]}: Multipart etag: #{s3_obj.etag}"
							s3_obj.copy_to("#{art[:key]}.copy")
							s3_obj = bucket.objects["#{art[:key]}.copy"]
							s3_obj.move_to(art[:key])
							s3_obj = bucket.objects[art[:key]]
							@logger.debug "#{art[:label]}: Revised etag: #{s3_obj.etag}"
						else
							@logger.warn "#{art[:label]}: Multipart etag: #{s3_obj.etag} on asset > 5Gb"
						end
					end
				end
			}
			0
		end

		# ---------------------------------------------------------------------------------------------------------------
		def initInventory()
			<<-EOJSON
{
  "id":   "#{@vars[:project_name]}",
  "gen":  "In case future generations introduce incompatible features",
  "gen":  "#{@options[:gen]}",
  "container":  {
    "artifacts":["assembly","metainfo","checksum","makefile"],
    "naming":   "<product>-<major>.<minor>.<patch>-<branch>-build-<number>.<extension>",
    "assembly": { "extension": "tar.gz", "type": "targz" },
    "metainfo": { "extension": "MANIFEST.json", "type": "json" },
    "checksum": { "extension": "checksum", "type": "Digest::SHA256" },
    "makefile": { "extension": "make", "type": "drush" },
    "variants": {
      "#{@vars[:variant]}": {
        "latest": {
          "build":   0,
          "branch":  0,
          "version": 0
        },
        "versions": [ "#{@vars[:build_ver]}" ],
        "branches": [ "#{@vars[:build_bra]}" ],
        "builds": [
                    {
                      "drawer": "#{@vars[:build_nam]}",
                      "build": "#{@vars[:build_rel]}"
                    }
        ]
      }
    }
  }
}
EOJSON
		end

		# ---------------------------------------------------------------------------------------------------------------
		def takeInventory()
			def _update(hash, key, value)
				h = {}
				i = -1
				hash[key].each { |v| h[v] = i+=1 }
				unless h.has_key?(value)
					h[value] = h.keys.size # No -1 because this is evaluated BEFORE we make the addition!
				end
				hash[key] = h.sort_by { |_, v| v }.map { |v| v[0] }
				h[value]
			end

			# Read and parse in JSON
			json_s    = ''
			json      = nil
			varianth  = nil

			bucket = getS3Bucket()
			key    = "#{@vars[:project_name]}/INVENTORY.json"
			s3_obj = bucket.objects[key]
			# If the inventory has started then add to it
			if s3_obj.exists?
				s3_obj.read(){|chunk|
					json_s << chunk
				}
				json = Yajl::Parser.parse(json_s)
				over = false
				# Is the inventory format is up to date ...
				require 'chef/exceptions'
				require 'chef/version_constraint'
				require 'chef/version_class'

				begin
					version     = Chef::Version.new(json['gen'])
				rescue Chef::Exceptions::InvalidCookbookVersion => e
					json['gen'] = "#{json['gen']}.0.0"
					version     = Chef::Version.new(json['gen'])
				end

				begin
					our_ver    = Chef::Version.new(@options[:gen])
					constraint = Chef::VersionConstraint.new("<= #{@options[:gen]}")
				rescue Chef::Exceptions::InvalidVersionConstraint => e
					raise TWC_CMS::Builder::Errors::InvalidVersionConstraint.new e.message
				rescue Chef::Exceptions::InvalidCookbookVersion => e
					raise TWC_CMS::Builder::Errors::InvalidVersion.new e.message
				end

				unless constraint.include?(version)
					raise TWC_CMS::Builder::Errors::InvalidVersion.new "The inventory generation is newer than I can manage: #{version} <=> #{our_ver}"
				end
				if  json['container'] and json['container']['variants']
					# but does not have our variant then add it
					variants = json['container']['variants']
					unless json['container']['variants'][@vars[:variant]]
						variants[@vars[:variant]] = {}
						varianth                  = variants[@vars[:variant]]
						varianth['builds']        = []
						varianth['branches']      = []
						varianth['versions']      = []
						varianth['latest']        = {
																          branch:  -1,
																          version: -1,
																          build:   -1,
																        }
					end
					varianth                  = variants[@vars[:variant]]
					# If the inventory 'latest' format is up to date ...
					unless  varianth['latest'] and
									varianth['latest'].is_a?(Hash)
						# Attempt to patch it!
						build = varianth['builds'][varianth['latest']]['build']
						varianth['latest']        = {
							branch:  0,
							version: 0,
							build:   varianth['latest'],
						}
						matches = build.match(/^(\w+)\-([0-9\.]+)\-(\w+)\-build\-(\d+)/)
						if matches
							if varianth['versions'] and varianth['branches']
								# Add new version ...
								build_ver                    = _update(varianth, 'versions', matches[2])
								# Add new branch ...
								build_bra                    = _update(varianth, 'branches', matches[3])
								varianth['latest'][:version] = build_ver
								varianth['latest'][:branch]  = build_bra
							else
								varianth['versions']         = [matches[2]]
								varianth['branches']         = [matches[3]]
							end
						end
					end
				else
					# Start over ... too old/ incompatible
					over = true
				end
			else
				# Start a new inventory
				over = true
			end
			# Starting fresh ?
			if over or json.nil?
				json_s = initInventory()
			else
				raise TWC_CMS::Builder::Errors::Internal.new sprintf("Internal logic error! %s::%d", __FILE__,__LINE__) if varianth.nil?
				# Add the new build if we don't have it
				unless varianth['builds'].map { |b| b['build'] }.include?(@vars[:build_rel])
					#noinspection RubyStringKeysInHashInspection
					varianth['builds'] <<
						{
							"drawer" => "#{@vars[:build_nam]}",
							"build"  => "#{@vars[:build_rel]}"
						}
				end
				build_lst = (varianth['builds'].size-1)

				# Add new branch ...
				build_bra = _update(varianth, 'branches', @vars[:build_bra])
				# Add new version ...
				build_ver = _update(varianth, 'versions', @vars[:build_ver])

				# Set latest
				varianth['latest'] = {
					branch:  build_bra,
					version: build_ver,
					build:   build_lst,
				}
				json['gen'] = @options[:gen]
				json_s = json.to_json
			end
			begin
				resp = s3_obj.write(:data => json_s)
				case resp.class.name
				when %r'^AWS::S3::(S3Object|ObjectVersion)'
					return 0
				else
					return 1
				end
			rescue Exception => e
				return -1
			end
		end

		# ---------------------------------------------------------------------------------------------------------------
		def uploadBuildArtifacts()
			if @vars.has_key?(:build_dir) and @vars.has_key?(:build_pkg)
				begin
					if File.exists?(@vars[:build_pkg])

						artifacts = []

						key    = "#{@vars[:project_name]}/#{@vars[:variant]}/#{@vars[:build_nam]}/#{@vars[:build_rel]}"
						# Store the assembly
						artifacts << {
							key:        "#{key}.tar.gz",
							data:       {:file => @vars[:build_pkg]},
							public_url: :build_url,
							label:      "Package URL"
						}

						# Store the metadata
						manifest = manifestMetadata()
						artifacts << {
							key:        "#{key}.MANIFEST.json",
							data:       {:data => manifest},
							public_url: :manifest_url,
							read_url:   :manifest_url,
							label:      "Manifest URL"
						}

						# Store the makefile
						artifacts << {
							key:        "#{@vars[:project_name]}/#{@vars[:variant]}/#{@vars[:build_nam]}/#{@vars[:build_rel]}.make",
							data:       {:file => @vars[:makefile_fil]},
							public_url: :makefile_url,
							read_url:   :makefile_url,
							label:      "Makefile URL"
						}

						# Store the checksum
						artifacts << {
							key:        "#{@vars[:project_name]}/#{@vars[:variant]}/#{@vars[:build_nam]}/#{@vars[:build_rel]}.checksum",
							data:       {:data => @vars[:build_sha]},
							public_url: :checksum_url,
							read_url:   :checksum_url,
							label:      "Checksum URL"
						}

						@vars[:return_code] = uploadToS3(artifacts)
						if 0 == @vars[:return_code]
							@vars[:return_code] = takeInventory()
						end
						@vars[:return_code]
					else
						@vars[:return_code] = 1
					end
				rescue => e
					@logger.error "#{e.class.name} #{e.message}"
					@vars[:return_code] = -99
					raise e
				end
			else
				@vars[:return_code] = 2
			end
			@vars[:return_code]
		end

		# ---------------------------------------------------------------------------------------------------------------
		def manifestMetadata
			manifest = @vars[:makefile_met].dup

			manifest[:manifest] = {
				version:  TWC_CMS::Builder::VERSION,
				major:    TWC_CMS::Builder::MAJOR,
				minor:    TWC_CMS::Builder::MINOR,
				patch:    TWC_CMS::Builder::PATCH,
			}

			version_number = "#{manifest[:projects][:drupal][:version]}.#{manifest[:Release]}"
			version_major, version_minor, version_patch = version_number.split('.')

			manifest[:version] = {
				number: version_number,
				major:  version_major,
				minor:  version_minor,
				patch:  version_patch,
				build:  @vars[:build_num],
				branch: @vars[:build_bra],
			}
			manifest[:build] = {
				name:     @vars[:build_rel],
				base:     @vars[:build_nam],
				date:     @vars[:build_dte],
				vrb:      @vars[:build_vrb],
				branch:   @vars[:build_bra],
				checksum: @vars[:build_sha],
			}
			# we want lowercase but if we use the existing key we don't have to delete it afterwards ...
			manifest[:Release] = {
				number:   manifest[:Release],
				branch:   manifest[:Branch],
				date:     manifest[:Date],
				api:      manifest[:api],
				core:     manifest[:core],
				checksum: @vars[:makefile_sha],
			}
			manifest.delete(:Date)
			manifest.delete(:api)
			manifest.delete(:core)
			manifest[:vars] = {}
			@vars.each { |k, v|
				unless %w(makefile_met makefile_txt).include?(k.to_s)
					manifest[:vars][k.to_s] = v
				end
			}
			manifest = downcaseHashKeys(manifest)
			manifest[:env] = {}
			ENV.each { |k, v|
				unless %w(LS_COLORS AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY).include?(k.to_s)
					manifest[:env][k.to_s] = v
				end
			}
			manifest.to_json
		end

	end
end