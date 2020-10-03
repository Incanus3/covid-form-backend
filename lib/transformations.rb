require 'dry/inflector'
require 'dry/transformer'

module Utils
  String = Dry::Inflector.new.freeze
  Array  = Dry::Transformer::ArrayTransformations
  Hash   = Dry::Transformer::HashTransformations

  module Transformations
    extend Dry::Transformer::Registry

    import Dry::Transformer::Coercions
    import Dry::Transformer::ArrayTransformations
    import Dry::Transformer::HashTransformations
    # import Dry::Transformer::ClassTransformations
    # import Dry::Transformer::ProcTransformations
    # import Dry::Transformer::Conditional
    # import Dry::Transformer::Recursion
  end

  T = Transformations
end
