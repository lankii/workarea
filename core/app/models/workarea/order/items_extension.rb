module Workarea
  class Order
    module ItemsExtension
      def find_existing(sku, attributes = {})
        customizations = attributes[:customizations] if attributes.present?
        customizations.stringify_keys! if customizations.present?

        detect do |item|
          item.sku == sku &&
            item.customizations_eql?(customizations) &&
              item.attributes_eql?(attributes.except(:customizations))
        end
      end
    end
  end
end
