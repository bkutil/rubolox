module Rubolox
  class Return < StandardError
    attr_reader :value

    def initialize(value)
      super(nil)
      @value = value
    end
  end
end
