Spree::Order.class_eval do

  has_one :order_subscription, class_name: "Spree::OrderSubscription", dependent: :destroy
  has_one :parent_subscription, through: :order_subscription, source: :subscription
  has_many :subscriptions, class_name: "Spree::Subscription",
                           foreign_key: :parent_order_id,
                           dependent: :destroy

  self.state_machine.after_transition to: :complete, do: :enable_subscriptions, if: :any_disabled_subscription?

  after_update :update_subscriptions

  def available_payment_methods
    if subscriptions.exists?
      @available_payment_methods = Spree::Gateway.active.available_on_front_end
    else
      @available_payment_methods ||= Spree::PaymentMethod.active.available_on_front_end
    end
  end

  private

    def enable_subscriptions
      return unless self.payment_required?
      subscriptions.each do |subscription|
        subscription.update(
          source: payments.first.try(:source),
          enabled: true,
          ship_address_id: ship_address_id,
          bill_address_id: bill_address_id
        )
      end
    end

    def any_disabled_subscription?
      subscriptions.disabled.any?
    end

    def update_subscriptions
      line_items.each do |line_item|
        if line_item.subscription_attributes_present?
          subscriptions.find_by(variant: line_item.variant).update(line_item.updatable_subscription_attributes)
        end
      end
    end

end
