require 'java'
require 'jruby'
require 'jruby/compiler/java_signature'

##
# Convenience methods added to class when you want to be able to
# reify a Ruby class into a honest to goodness type.  Typically, it would look
# like:
# :call-seq:
#
# class Foo
#   java_signature '@org.foo.EventHandler(@org.foo.Priority.High) void foo(int)'
#   def foo(number)
#   end
#   become_java!
# end 
#
# Although this will still just be an instance of a IRubyObject versus a 
# specific type, you can still use this facility for:
#   1. Adding runtime annotations to methods
#   2. Making a class still reflectable from Java reflection APIs.
#
# Case #1 above is also a useful combination with implementing Java interfaces.
#
class Class
  JClass = java.lang.Class
  private_constant :JClass

  ##
  # @deprecated since JRuby 9.2, use `JRuby.subclasses_of(klass)`
  def subclasses(recursive = false)
    warn("klass.subclasses is deprecated, use JRuby.subclasses(klass) instead", uplevel: 1)
    JRuby.subclasses(self, all: recursive)
  end

  ##
  # java_signature will take the argument and annotate the method of the
  # same name with the Java type and annotation signatures.
  # 
  # :call-seq:
  #   java_signature '@Override void foo(int)'
  #   java_signature '@Override void foo(int foo, org.foo.Bar bar)'
  def java_signature(signature_source)
    signature = JRuby::JavaSignature.parse signature_source
    add_method_signature signature.name, signature.types

    annotations = signature.annotations
    add_method_annotation signature.name, annotations if annotations
  end
  
  ##
  # Generate a native Java class for this Ruby class. If dump_dir is specified,
  # dump the JVM bytecode there for inspection. If child_loader is false, do not
  # generate the class into its own classloader (use the parent's loader).
  # 
  # :call-seq:
  #   become_java!
  #   become_java!(dump_dir)
  #   become_java!(dump_dir, child_loader)
  #   become_java!(child_loader)
  #   become_java!(child_loader, dump_dir)
  def become_java!(*args)
    # stub moved to org.jruby.java.addons.ClassJavaAddons
  end if false
  
  ##
  # Get the native or reified (a la become_java!) class for this Ruby class.
  def java_class
    current = JRuby.reference0(self)
    while current
      reified = current.reified_class
      return reified if reified
      current = JRuby.reference0(current.super_class)
    end
    
    nil
  end if false # moved to org.jruby.java.addons.ClassJavaAddons
  
  def _anno_class(type)
    return type if type.kind_of? JClass
    if type.respond_to? :java_class
      type.java_class.to_java :object
    else
      raise TypeError, "expected a Java class, got #{type}"
    end
  end
  private :_anno_class
  
  ##
  # Add annotations to the named method. Annotations are specified as a Hash
  # from the annotation classes to Hashes of name/value pairs for their 
  # parameters. Please refrain from using this in favor of java_signature.
  # :call-seq:
  #
  #  add_method_annotation :foo, {java.lang.Override => {}}
  #
  def add_method_annotation(name, annotations = {})
    name = name.to_s; self_r = JRuby.reference0(self)

    annotations.each do |type, params|
      self_r.add_method_annotation(name, _anno_class(type), params || {})
    end
    
    nil
  end
  
  ##
  # Add annotations to the parameters of the named method. Annotations are
  # specified as a parameter-list-length Array of Hashes from annotation classes
  # to Hashes of name/value pairs for their parameters.
  def add_parameter_annotation(name, annotations = [])
    name = name.to_s; self_r = JRuby.reference0(self)
    
    annotations.each_with_index do |param_annos, i|
      for cls, params in param_annos
        params ||= {}
        self_r.add_parameter_annotation(name, i, _anno_class(cls), params)
      end
    end
    
    nil
  end
  
  ##
  # Add annotations to this class. Annotations are specified as a Hash of
  # annotation classes to Hashes of name/value pairs for their parameters.
  # :call-seq:
  #
  # add_class_annotation java.lang.TypeAnno => {"type" => @com.foo.GoodOne}
  #
  def add_class_annotations(annotations = {})
    self_r = JRuby.reference0(self)

    annotations.each do |type, params|
      self_r.add_class_annotation(_anno_class(type), params || {})
    end
    
    nil
  end

  ##
  # Add a Java signaturefor the named method. The signature is specified as
  # an array of Java classes where the first class specifies the return
  # type.
  # :call-seq:
  #
  # add_method_signature :foo, [:void, :int, java.lang.Thread]
  #
  def add_method_signature(name, classes)
    name = name.to_s; self_r = JRuby.reference0(self)
    types = classes.inject([]) { |arr, klass| arr << _anno_class(klass) }
    
    self_r.add_method_signature(name, types.to_java(JClass))
  end

  ##
  # java_field will take the argument and create a java field as defined
  # with the name, the Java type, and the annotation signatures.
  # 
  # :call-seq:
  #   java_field '@FXML int foo'
  #   java_field 'org.foo.Bar bar'
  def java_field(signature_source)
    signature = JRuby::JavaSignature.parse "#{signature_source}()"

    add_field_signature signature.name, signature.return_type

    annotations = signature.annotations
    add_field_annotation signature.name, annotations if annotations
  end
  
  ##
  # Valid options:
  # call_init: true/false
  # generate: :all/:explicit
  #    configure_java_class methods: :explicit/:all, call_init: true/false, java_constructable: true/false, ctors: :all/:minimal
  def configure_java_class(**kwargs)
    self_r = JRuby.reference0(self)
    config = self_r.class_config
    config.allMethods = kwargs[:methods] == :explicit if kwargs.has_key? :methods
    config.callInitialize = kwargs[:call_init] if kwargs.has_key? :call_init
    config.javaConstructable = kwargs[:java_constructable] if kwargs.has_key? :java_constructable
    config.allCtors = kwargs[:ctors] == :all if kwargs.has_key? :ctors
    config.rubyConstructable = kwargs[:ruby_constructable] if kwargs.has_key? :ruby_constructable
    config.splitSuper = kwargs[:split_super] if kwargs.has_key? :split_super
    self_r.class_config = config
    kwargs
  end
  
  #Temporary, TODO: nicer api
  def extra_ctor(*clz)
    self_r = JRuby.reference0(self)
    config = self_r.class_config
    config.extraCtors = [clz.to_java(java.lang.Class)].to_java(java.lang.Class[])
  end

  def java_annotation(anno)
    warn "java_annotation is deprecated. Use java_signature '@#{anno} ...' instead. Called from: #{caller.first}"
  end
  

  def add_field_signature(name, type)
    self_r = JRuby.reference0(self)

    java_return_type = _anno_class(type)

    self_r.add_field_signature(name, java_return_type.to_java(JClass))
  end

  def add_field_annotation(name, annotations = {})
    name = name.to_s; self_r = JRuby.reference0(self)

    annotations.each do |type, params|
      self_r.add_field_annotation(name, _anno_class(type), params || {})
    end

    nil
  end

end
