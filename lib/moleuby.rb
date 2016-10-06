require "moleuby/version"

module Moleuby
  require "set"

  class Molebox
    def initialize(application)
      @base = application
      @virt = application.clone
    end

    def run(&block)
      @virt.instance_eval &block
    end

    def locals
      base_vars = Set.new(@base.instance_variables)
      hash = @virt
             .instance_variables
             .select {|var| !(base_vars.include? var)}
             .map    {|var| {trim(var) => dict(@virt,var)}}
             .inject({}) {|ret,h| ret.merge(h)}
      return Hashie::Mash.new(hash)
    end

    def method_missing(name, *args)
      @virt.send(name,*args)
    end

    private

    def dict(instance,var)
      return instance.instance_variable_get(var)
    end

    def trim(var)
      return var.to_s[1..-1].to_sym
    end

    def diff
      @base.instance_variables.select do |var|
        (dict(@base,var) == dict(@virt,var)) ? false : true
      end
    end
  end

  def self.digging(&block)
    @digging ||= Molebox.new(self)
    @digging.run &block if block
    return @digging
  end
end
