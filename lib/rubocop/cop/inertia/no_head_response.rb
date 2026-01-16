# frozen_string_literal: true

module RuboCop
  module Cop
    module Inertia
      # Detects usage of `head` responses in Inertia controllers.
      #
      # Inertia.js requires a full response from every controller action.
      # Status-only responses like `head :ok` will cause Inertia errors.
      #
      # @example
      #   # bad
      #   class ItemsController < InertiaController
      #     def reorder
      #       @item.update_position(params[:position])
      #       head :ok
      #     end
      #   end
      #
      #   # good
      #   class ItemsController < InertiaController
      #     def reorder
      #       @item.update_position(params[:position])
      #       redirect_back fallback_location: items_path
      #     end
      #   end
      #
      class NoHeadResponse < Base
        MSG = "Inertia controllers cannot use `head` responses. Use `redirect_to`, `redirect_back`, or `render inertia:` instead."

        RESTRICT_ON_SEND = [ :head ].freeze

        def_node_matcher :inertia_controller_class?, <<~PATTERN
          (class (const nil? _) (const nil? :InertiaController) ...)
        PATTERN

        def on_send(node)
          return unless in_inertia_controller?(node)

          add_offense(node)
        end

        private

        def in_inertia_controller?(node)
          node.each_ancestor(:class).any? do |class_node|
            inherits_from_inertia_controller?(class_node)
          end
        end

        def inherits_from_inertia_controller?(class_node)
          parent_class = class_node.parent_class
          return false unless parent_class

          parent_class_name = parent_class.const_name
          parent_class_name == "InertiaController" || parent_class_name&.end_with?("Controller")
        end
      end
    end
  end
end
