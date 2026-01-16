# frozen_string_literal: true

module RuboCop
  module Cop
    module Inertia
      # Detects usage of `render json:` in Inertia controllers.
      #
      # Inertia.js requires `render inertia:` for page responses. Using
      # `render json:` will break the frontend navigation flow.
      #
      # @example
      #   # bad
      #   class ItemsController < InertiaController
      #     def show
      #       render json: @item
      #     end
      #   end
      #
      #   # good
      #   class ItemsController < InertiaController
      #     def show
      #       render inertia: "items/show", props: { item: @item.as_json(only: %i[id name]) }
      #     end
      #   end
      #
      class ExplicitInertiaRender < Base
        MSG = "Use `render inertia:` instead of `render json:` in Inertia controllers."

        RESTRICT_ON_SEND = [ :render ].freeze

        def_node_matcher :render_json?, <<~PATTERN
          (send nil? :render (hash <(pair (sym :json) _) ...>))
        PATTERN

        def on_send(node)
          return unless render_json?(node)
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
