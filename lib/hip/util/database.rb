module Hip
  module Util
    class Database
      def self.sequel_development
        @sequel_development ||= sequel_for_environment('development')
      end

      def self.sequel_test
        @sequel_development ||= sequel_for_environment('test')
      end

      def self.sequel_staging
        @sequel_staing ||= begin
          require 'sequel'
          raise "The HIP_STAGING_DB_PASSWORD environment variable isn't set" unless ENV["HIP_STAGING_DB_PASSWORD"]
          Sequel.connect(sequel_staging_config)
        end
      end

      def self.sequel_staging_config
        {
          "adapter"  => "ibmdb",
          "host"     => "msd-bld-dba-08t.boulder.ibm.com",
          "port"     => 60000,
          "username" => "hip",
          "password" => ENV["HIP_STAGING_DB_PASSWORD"],
          "database" => "sware",
          "schema"   => "hip",
        }
      end

      private

      def self.sequel_for_environment(environment_name)
        require 'sequel'
        config = Rails.configuration.database_configuration[environment_name].clone
        config['adapter'] = 'ibmdb'
        Sequel.connect(config)
      end

    end
  end
end
