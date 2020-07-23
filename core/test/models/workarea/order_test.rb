require 'test_helper'

module Workarea
  decorate Order::Item, with: :workarea_order_test do
    decorated do
      field :custom, type: String
    end
  end

  class OrderTest < TestCase
    def test_quantity
      order = Order.new

      assert_equal(0, order.quantity)
      assert(order.no_items?)

      order.items.build(product_id: 'PROD', sku: 'SKU1', quantity: 1)
      assert_equal(1, order.quantity)

      order.items.build(product_id: 'PROD', sku: 'SKU2', quantity: 2)
      assert_equal(3, order.quantity)

      order.items.build(quantity: 2)
      assert_equal(3, order.quantity)
    end

    def test_purchasable?
      order = Order.new
      refute(order.purchasable?)

      order.email = 'test@workarea.com'
      refute(order.purchasable?)

      order.items.build(product_id: '1', sku: 'SKU1', quantity: 1)
      assert(order.purchasable?)
    end

    def test_place
      order = Order.new(email: 'test@workarea.com')
      order.place

      refute(order.placed?)

      order.items.build(product_id: 'PROD', sku: 'SKU1')
      order.place

      assert(order.placed?)
    end

    def test_cancel
      order = Order.new
      order.cancel
      assert(order.canceled?)
    end

    def test_status
      order = Order.new(email: 'test@workarea.com', created_at: Time.current)
      order.items.build(product_id: 'PROD', sku: 'SKU1')

      assert_equal(:cart, order.status)

      order.checkout_started_at = Time.current
      assert_equal(:checkout, order.status)

      order.place
      assert_equal(:placed, order.status)

      order.cancel
      assert_equal(:canceled, order.status)

      order = Order.new(created_at: Time.current - 1.day)
      assert_equal(:abandoned, order.status)
    end

    def test_add_item
      order = Order.new(email: 'test@workarea.com')

      assert_difference('order.quantity', 2) do
        order.add_item(product_id: '1234', sku: 'SKU', quantity: 2)
      end

      assert_equal('1234', order.items.last.product_id)
      assert_equal('SKU', order.items.last.sku)
      assert_equal(2, order.items.last.quantity)
      assert(order.items.last.created_at.present?)
      assert(order.items.last.updated_at.present?)

      order.add_item(product_id: '1234', sku: 'SKU', quantity: 2)
      assert_equal(1, order.items.count)
      assert_equal(4, order.items.last.quantity)

      order.add_item(product_id: '1234', sku: 'SKU', quantity: 1, custom: 'foo')
      assert_equal(1, order.items.count)
      assert_equal(5, order.items.last.quantity)
      assert_equal('foo', order.items.last.custom)
    end

    def test_update_item
      order = Order.new
      item = order.items.build(product_id: '1234', sku: 'SKU', quantity: 2)

      order.update_item(item.id, quantity: 1)
      assert_equal(1, order.items.first.quantity)

      order.update_item(item.id, sku: 'SKU2')
      assert_equal(1, order.items.count)
      assert_equal('SKU2', order.items.first.sku)

      order = Order.new
      item_one = order.items.build(product_id: '1234', sku: 'SKU1', quantity: 2)
      item_two = order.items.build(product_id: '1234', sku: 'SKU2', quantity: 1)

      assert_equal(2, order.items.length)
      assert(order.has_sku?('SKU2'))
      assert_equal(2, item_one.quantity)

      order.update_item(item_two.id, sku: 'SKU1')

      assert_equal(1, order.items.length)
      assert_equal(3, item_one.quantity)
    end

    def test_remove_item
      order = Order.new
      item = order.items.build(product_id: '1234', sku: 'SKU', quantity: 2)

      order.remove_item(item.id)
      assert(0, order.quantity)
      assert(order.items.empty?)
    end

    def test_add_promo_code
      order = Order.new

      order.add_promo_code('PROMOCODE1234')
      assert_includes(order.promo_codes, 'PROMOCODE1234')

      order.add_promo_code('PROMOCODE1234')
      assert_equal(1, order.promo_codes.count { |c| c == 'PROMOCODE1234' })

      order.add_promo_code('pRoMoCoDe1234')
      assert_equal(1, order.promo_codes.length)
      assert_equal('PROMOCODE1234', order.promo_codes.first)
    end

    def test_items_find_existing
      order = Order.new

      item = order.items.build(sku: 'sku')
      assert_equal(item, order.items.find_existing('sku'))

      item.customizations = { 'email' => 'bcrouse@workarea.com' }
      assert(order.items.find_existing('sku').blank?)
      assert_equal(
        item,
        order.items.find_existing('sku', { 'email' => 'bcrouse@workarea.com' })
      )
    end

    def test_name
      order = Order.new
      assert_equal("Order #{order.id}", order.name)
    end
  end
end
