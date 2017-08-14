module Vagrant
  module Vmpool
    class Config < Vagrant.plugin(2, :config)
      attr_accessor :name

      def initialize
        @name = UNSET_VALUE
      end

      def validate(machine)
        errors = _detected_errors
        # TODO: validations
        { 'vmpool' => errors }
      end

      def finalize!
        @name = nil if @name == UNSET_VALUE
      end
    end
  end
end
