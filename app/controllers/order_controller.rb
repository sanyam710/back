require 'sendgrid-ruby'
include SendGrid

class OrderController < ApplicationController

    def add_order
        unless has_sufficient_params(['table_id','order_details'])
            return
        end
        table = RestaurantTable.find params[:table_id]
        unless table
            render_error_json 'Table not found!'
            return
        end
        if !params[:table_order_id].present?
            table_order = TableOrder.new
            table_order.table_id = table.id
            table_order.status_id = ORDER_ONGOING
            table_order.customer_name = params[:customer_name]
            table_order.customer_email = params[:customer_email]
            table_order.customer_address = params[:customer_address]
            table_order.customer_mobile_no = params[:customer_mobile_no]
            table_order.save
        else
            table_order = TableOrder.find_by_id(params[:table_order_id])
        end
        
        if !params[:sub_order_id].present?
            table_sub_order = TableSubOrder.new
            table_sub_order.table_order_id = table_order.id
            table_sub_order.status_id = ORDER_ONGOING
            # table_sub_order.instruction = params[:instruction]
            table_sub_order.save
        else
            table_sub_order = TableSubOrder.find_by_id(params[:sub_order_id])
            table_sub_order.sub_order_details.delete_all if table_sub_order.id.present?
        end
        

        total_sub_order_price = 0
        params[:order_details].each do |food_item|
            
            
            if food_item['sub_order_details_id'].present?
                table_sub_order_details = TableSubOrderDetail.find_by_id(food_item['sub_order_details_id'])
            else
                table_sub_order_details = TableSubOrderDetail.new
            end
            
            table_sub_order_details.sub_order_id = table_sub_order.id
            table_sub_order_details.recipe_id = food_item['id']
            table_sub_order_details.quantity = food_item['quantity']
            table_sub_order_details.current_price = food_item['current_price']
            table_sub_order_details.recipe_child_id = food_item['recipe_child_id'] if food_item['recipe_child_id'].present?
            table_sub_order_details.child_current_price = food_item['child_current_price'] if food_item['child_current_price'].present?
            table_sub_order_details.child_name = food_item['child_name'] if food_item['child_name'].present?
            if food_item['recipe_child_id'].present? && food_item['child_current_price'].present?
                table_sub_order_details.current_total_price = food_item['child_current_price'].to_i * food_item['quantity'].to_i
            else
                table_sub_order_details.current_total_price = food_item['current_price'].to_i * food_item['quantity'].to_i
            end
            table_sub_order_details.name = food_item['name']
            table_sub_order_details.instruction = food_item['instruction']
            table_sub_order_details.save
            if food_item['child_current_price'].present?
                total_sub_order_price += food_item['child_current_price'].to_i * food_item['quantity'].to_i
            else 
                total_sub_order_price += food_item['current_price'].to_i * food_item['quantity'].to_i
            end
        end

        table_sub_order.update_attributes(total_price: total_sub_order_price)

        table_order = TableOrder.includes(sub_orders: [sub_order_details: [food_item: :images]]).find_by_id(table_order.id)
        table_sub_orders = table_order.sub_orders
        sub_orders_arr = []
        if table_sub_orders.present?
            table_sub_orders.each do |sub_order|
                sub_order_details = sub_order.sub_order_details
                if sub_order_details.present?
                    sub_order_details_arr = []
                    sub_order_details.each do |food_item|
                        if food_item.name.present?
                            name = food_item.name
                        else
                            name = food_item.food_item.name
                        end
                        obj = {}
                        obj['id'] = food_item.id
                        obj['recipe_id'] = food_item.recipe_id
                        obj['quantity'] = food_item.quantity
                        obj['recipe_name'] = name
                        obj['child_name'] = food_item.child_name
                        obj['child_price'] = food_item.child_current_price
                        obj['current_price'] = food_item.current_price
                        obj['current_total_price'] = food_item.current_total_price
                        obj['instruction'] = food_item.instruction
                        obj['images'] = food_item.food_item.images.pluck(:url) rescue []
                        sub_order_details_arr << obj
                    end
                end
                obj = {}
                obj['id'] = sub_order.id
                obj['total_price'] = sub_order.total_price
                obj['instruction'] = sub_order.instruction
                obj['status_id'] = sub_order.status_id
                obj['sub_order_details'] = sub_order_details_arr
                sub_orders_arr << obj
            end
        end
        obj = {}
        obj['id'] = table_order.id
        obj['table_id'] = table_order.table_id
        obj['table_name'] = table_order.table.name rescue nil
        obj['total_price'] = table_order.total_price
        obj['status_id'] = table_order.status_id
        obj['sub_orders'] = sub_orders_arr

        # map = {}
        # map['order_id'] = table_order.id
        render_result_json obj
    end

    def update_sub_order
        unless has_sufficient_params(['sub_order_id'])
            return
        end
        table_sub_order = TableSubOrder.find_by_id(params[:sub_order_id])
        unless table_sub_order
            render_error_json 'Sub Order is not present.'
            return
        end
        if params[:sub_order_details].present?
            food_items = table_sub_order.food_items
            if food_items.present?
                food_items.destroy_all
            end
            total_sub_order_price = 0
            params[:sub_order_details].each do |food_item|
                table_sub_order_details = TableSubOrderDetail.new
                table_sub_order_details.sub_order_id = table_sub_order.id
                table_sub_order_details.recipe_id = food_item['id']
                table_sub_order_details.quantity = food_item['quantity']
                table_sub_order_details.current_price = food_item['current_price']
                table_sub_order_details.current_total_price = food_item['current_price'].to_i * food_item['quantity'].to_i
                table_sub_order_details.name = food_item['name']
                table_sub_order_details.save
                total_sub_order_price += food_item['current_price'].to_i * food_item['quantity'].to_i
            end
            table_sub_order.update_attributes(total_price: total_sub_order_price)
        end
        if params[:status_id].present?
            table_sub_order.update_attributes(status_id: params[:status_id])
        end
        render_success_json 'Sub order updated!'
    end

    def update_order
        unless has_sufficient_params(['order_id'])
            return
        end
        table_order = TableOrder.find_by_id(params[:order_id])
        unless table_order
            render_error_json 'Sub Order is not present.'
            return
        end
        table_order.update_attributes(status_id: params[:status_id])
        render_success_json 'Order updated!'
    end


    def get_table_ongoing_order_details
        unless has_sufficient_params(['table_id'])
            return
        end
        table = RestaurantTable.includes(ongoing_order: [sub_orders: [sub_order_details: [food_item: :images]]]).find_by_id(params[:table_id])
        table_order = table.ongoing_order
        unless table_order
            render_error_json 'No ongoing order present.'
            return
        end
        table_sub_orders = table_order.sub_orders
        sub_orders_arr = []
        if table_sub_orders.present?
            table_sub_orders.each do |sub_order|
                sub_order_details = sub_order.sub_order_details
                if sub_order_details.present?
                    sub_order_details_arr = []
                    sub_order_details.each do |food_item|
                        if food_item.name.present?
                            name = food_item.name
                        else
                            name = food_item.food_item.name
                        end
                        obj = {}
                        obj['recipe_id'] = food_item.recipe_id
                        obj['quantity'] = food_item.quantity
                        obj['recipe_name'] = name
                        obj['child_name'] = food_item.child_name
                        obj['child_price'] = food_item.child_current_price
                        obj['current_price'] = food_item.current_price
                        obj['current_total_price'] = food_item.current_total_price
                        obj['images'] = food_item.food_item.images.pluck(:url) rescue []
                        sub_order_details_arr << obj
                    end
                end
                obj = {}
                obj['id'] = sub_order.id
                obj['total_price'] = sub_order.total_price
                obj['instruction'] = sub_order.instruction
                obj['status_id'] = sub_order.status_id
                obj['sub_order_details'] = sub_order_details_arr
                sub_orders_arr << obj
            end
        end
        obj = {}
        obj['id'] = table_order.id
        obj['table_id'] = table_order.table_id
        obj['total_price'] = table_order.total_price
        obj['status_id'] = table_order.status_id
        obj['instruction'] = table_order.instruction
        obj['customer_address'] = table_order.customer_address
        obj['customer_email'] = table_order.customer_email
        obj['customer_mobile_no'] = table_order.customer_mobile_no
        obj['customer_name'] = table_order.customer_name
        obj['total_price'] = table_order.total_price
        obj['sub_orders'] = sub_orders_arr
        render_result_json obj
    end

    def get_order_details
        unless has_sufficient_params(['order_id'])
            return
        end
        table_order = TableOrder.includes(sub_orders: [sub_order_details: [food_item: :images]]).find_by_id(params[:order_id])
        unless table_order
            render_error_json 'Order not present.'
            return
        end
        table_sub_orders = table_order.sub_orders
        sub_orders_arr = []
        if table_sub_orders.present?
            table_sub_orders.each do |sub_order|
                sub_order_details = sub_order.sub_order_details
                if sub_order_details.present?
                    sub_order_details_arr = []
                    sub_order_details.each do |food_item|
                        if food_item.name.present?
                            name = food_item.name
                        else
                            name = food_item.food_item.name
                        end
                        obj = {}
                        obj['id'] = food_item.id
                        obj['recipe_id'] = food_item.recipe_id
                        obj['quantity'] = food_item.quantity
                        obj['recipe_name'] = name
                        obj['child_name'] = food_item.child_name
                        obj['child_price'] = food_item.child_current_price
                        obj['current_price'] = food_item.current_price
                        obj['current_total_price'] = food_item.current_total_price
                        obj['images'] = food_item.food_item.images.pluck(:url) rescue []
                        obj['instruction'] = food_item.instruction
                        sub_order_details_arr << obj
                    end
                end
                obj = {}
                obj['id'] = sub_order.id
                obj['total_price'] = sub_order.total_price
                # obj['instruction'] = sub_order.instruction
                obj['status_id'] = sub_order.status_id
                obj['sub_order_details'] = sub_order_details_arr
                sub_orders_arr << obj
            end
        end
        obj = {}
        obj['id'] = table_order.id
        obj['table_id'] = table_order.table_id
        obj['table_name'] = table_order.table.name rescue nil
        obj['total_price'] = table_order.total_price
        obj['customer_name'] = table_order.customer_name
        obj['customer_email'] = table_order.customer_email
        obj['customer_address'] = table_order.customer_address
        obj['customer_mobile_no'] = table_order.customer_mobile_no
        obj['status_id'] = table_order.status_id
        obj['sub_orders'] = sub_orders_arr
        render_result_json obj
    end

    def get_order_collective_details
        unless has_sufficient_params(['order_id'])
            return
        end
        table_order = TableOrder.includes(sub_orders: [sub_order_details: [food_item: :images]]).find_by_id(params[:order_id])
        unless table_order
            render_error_json 'Order not present.'
            return
        end
        table_sub_orders = table_order.sub_orders
        sub_orders_arr = []
        temp_recipe_ids = []
        if table_sub_orders.present?
            table_sub_orders.each do |sub_order|
                sub_order_details = sub_order.sub_order_details
                if sub_order_details.present?
                    sub_order_details_arr = []
                    sub_order_details.each do |food_item|
                        if food_item.name.present?
                            name = food_item.name
                        else
                            name = food_item.food_item.name
                        end
                        if temp_recipe_ids.include?(food_item.recipe_id)
                            sub_orders_arr[0]['sub_order_details'].each do |so_details|
                                if so_details['recipe_id'] == food_item.recipe_id
                                    so_details['current_total_price'] += food_item.current_total_price
                                    so_details['quantity'] += food_item.quantity
                                end
                            end
                        else
                            obj = {}
                            obj['recipe_id'] = food_item.recipe_id
                            obj['quantity'] = food_item.quantity
                            obj['recipe_name'] = name
                            obj['current_price'] = food_item.current_price
                            obj['current_total_price'] = food_item.current_total_price
                            temp_recipe_ids << food_item.recipe_id
                            sub_order_details_arr << obj
                        end
                    end
                end
                obj = {}
                obj['sub_order_details'] = sub_order_details_arr
                sub_orders_arr << obj
            end
        end
        all_recipes = []
        sub_orders_arr.each do |so_details|
            all_recipes << so_details['sub_order_details'].concat()
        end
        all_recipes = all_recipes.reject { |recipe| recipe.empty? }
        final_recipes = []
        all_recipes.each do |arr_obj|
            arr_obj.each do |arr|
                final_recipes << arr
            end
        end

        obj = {}
        obj['id'] = table_order.id
        obj['customer_name'] = table_order.customer_name
        obj['customer_email'] = table_order.customer_email
        obj['customer_address'] = table_order.customer_address
        obj['customer_mobile_no'] = table_order.customer_mobile_no
        obj['table_id'] = table_order.table_id
        obj['table_name'] = table_order.table.name rescue nil
        obj['total_price'] = table_order.total_price
        obj['status_id'] = table_order.status_id
        obj['recipe_details'] = final_recipes
        render_result_json obj
    end

    def add_billing_order
        unless has_sufficient_params(['order_details'])
            return
        end

        table = nil
        if params[:table_id].present?
            table = RestaurantTable.find params[:table_id]
        else
            user = User.where(api_key: params[:api_key]).first
            table = RestaurantTable.where(restaurant_id: user.id, name: 'Table-0').first
        end

        if !params[:table_order_id].present?
            table_order = TableOrder.new
            table_order.table_id = table.id if table.present?
            table_order.status_id = ORDER_ONGOING
            table_order.customer_name = params[:customer_name]
            table_order.customer_email = params[:customer_email]
            table_order.customer_address = params[:customer_address]
            table_order.customer_mobile_no = params[:customer_mobile_no]
            table_order.save
        else
            table_order = TableOrder.find_by_id(params[:table_order_id])
        end

        if table_order.sub_orders.present?
            table_sub_order = table_order.sub_orders.first
        else
            table_sub_order = TableSubOrder.new
            table_sub_order.table_order_id = table_order.id
            table_sub_order.status_id = ORDER_ONGOING
            table_sub_order.instruction = params[:instruction]
            table_sub_order.save
        end

        total_sub_order_price = table_sub_order.total_price.present? ? table_sub_order.total_price : 0
        params[:order_details].each do |food_item|
            table_sub_order_details = TableSubOrderDetail.new
            table_sub_order_details.sub_order_id = table_sub_order.id
            table_sub_order_details.recipe_id = food_item['id']
            table_sub_order_details.quantity = food_item['quantity']
            table_sub_order_details.current_price = food_item['current_price']
            table_sub_order_details.recipe_child_id = food_item['recipe_child_id'] if food_item['recipe_child_id'].present?
            table_sub_order_details.child_current_price = food_item['child_current_price'] if food_item['recipe_child_id'].present?
            table_sub_order_details.child_name = food_item['child_name'] if food_item['child_name'].present?
            if food_item['recipe_child_id'].present? && food_item['child_current_price'].present?
                table_sub_order_details.current_total_price = food_item['child_current_price'].to_i * food_item['quantity'].to_i
            else
                table_sub_order_details.current_total_price = food_item['current_price'].to_i * food_item['quantity'].to_i
            end
            table_sub_order_details.name = food_item['name']
            table_sub_order_details.save
            total_sub_order_price += food_item['current_price'].to_i * food_item['quantity'].to_i
        end

        table_sub_order.update_attributes(total_price: total_sub_order_price)

        map = {}
        map['order_id'] = table_order.id
        render_result_json map
    end

    def update_billing_order
        unless has_sufficient_params(['table_order_id','order_details'])
            return
        end

        table_order = TableOrder.find_by_id(params[:table_order_id])
        table_sub_order = table_order.sub_orders.first

        total_sub_order_price = table_sub_order.total_price.present? ? table_sub_order.total_price : 0
        table_sub_orders_details = table_sub_order.sub_order_details
        table_sub_orders_details.delete_all
        params[:order_details].each do |food_item|
            table_sub_order_details = TableSubOrderDetail.new
            table_sub_order_details.sub_order_id = table_sub_order.id
            table_sub_order_details.recipe_id = food_item['id']
            table_sub_order_details.quantity = food_item['quantity']
            table_sub_order_details.current_price = food_item['current_price']
            table_sub_order_details.current_total_price = food_item['current_price'].to_i * food_item['quantity'].to_i
            table_sub_order_details.name = food_item['name']
            table_sub_order_details.save
            total_sub_order_price += food_item['current_price'].to_i * food_item['quantity'].to_i
        end

        table_sub_order.update_attributes(total_price: total_sub_order_price)

        map = {}
        map['order_id'] = table_order.id
        render_result_json map
    end

    def get_table_orders
        unless has_sufficient_params(['table_id'])
            return
        end
        table = RestaurantTable.includes(:orders).find_by_id(params[:table_id])
        unless table
            render_error_json 'Table not found.'
            return
        end
        orders = table.orders
        render_result_json orders
    end

    def get_table_ongoing_order
        unless has_sufficient_params(['table_id'])
            return
        end
        table = RestaurantTable.includes(:orders).find_by_id(params[:table_id])
        unless table
            render_error_json 'Table not found.'
            return
        end
        orders = table.orders.where(status_id: ORDER_ONGOING)
        render_result_json orders
    end

    def delete_sub_order
        unless has_sufficient_params(['sub_order_id'])
            return
        end
        table_sub_order = TableSubOrder.find_by_id(params[:sub_order_id])
        unless table_sub_order
            render_error_json 'Sub order not found!'
            return
        end
        table_sub_order.destroy
        obj = {}
        obj = table_sub_order.table_order
        render_result_json obj # returning a updated price after deletion
    end

end
