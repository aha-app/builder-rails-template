# frozen_string_literal: true

module RuboCop
  module Cop
    module Inertia
      # Detects manual error formatting instead of using `inertia_errors` helper.
      #
      # The `inertia_errors` helper provides consistent error formatting for
      # Inertia.js forms. Using it ensures errors are properly structured.
      #
      # @example
      #   # bad
      #   render inertia: "items/new", props: { item: item, errors: item.errors.to_hash }
      #   render inertia: "items/new", props: { errors: @item.errors.messages }
      #
      #   # good
      #   render inertia: "items/new", props: { item: item }.merge(inertia_errors(item))
      #
      class UseInertiaErrors < Base
        MSG = "Use `inertia_errors(model)` helper instead of manually formatting errors."

        def_node_matcher :render_inertia_with_props?, <<~PATTERN
          (send nil? :render (hash <(pair (sym :inertia) _) (pair (sym :props) $(...)) ...>))
        PATTERN

        def_node_matcher :errors_in_hash?, <<~PATTERN
          (hash <(pair (sym :errors) (send (send _ :errors) ...)) ...>)
        PATTERN

        def_node_matcher :errors_key_with_model_errors?, <<~PATTERN
          (pair (sym :errors) (send (send _ :errors) ...))
        PATTERN

        def on_send(node)
          return unless node.method_name == :render

          props_node = render_inertia_with_props?(node)
          return unless props_node

          check_hash_for_manual_errors(props_node)
        end

        private

        def check_hash_for_manual_errors(node)
          return unless node.hash_type?

          node.each_pair do |key, value|
            next unless key.sym_type? && key.value == :errors
            next unless calls_errors_on_model?(value)

            pair_node = node.pairs.find { |p| p.key == key }
            add_offense(pair_node) if pair_node
          end
        end

        def calls_errors_on_model?(node)
          return false unless node.send_type?

          receiver = node.receiver
          return false unless receiver&.send_type?

          receiver.method_name == :errors
        end
      end
    end
  end
end
