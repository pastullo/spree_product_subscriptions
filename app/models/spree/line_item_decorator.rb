Spree::LineItem.class_eval do

  attr_accessor :subscription_frequency_id, :delivery_number, :subscribe

  after_create :create_subscription!, if: :subscribable?
  after_update :update_subscription_quantity, if: :can_update_subscription_quantity?
  # after_update :update_subscription_attributes, if: :can_update_subscription_attributes?
  after_destroy :destroy_associated_subscription!, if: :subscription?

  def subscription_attributes_present?
    subscription_frequency_id.present? || delivery_number.present?
  end

  def updatable_subscription_attributes
    {
      subscription_frequency_id: subscription_frequency_id || subscription.subscription_frequency_id,
      delivery_number: delivery_number || subscription.delivery_number
    }
  end

  def subscribable?
    # skip if the user already has an active subscription for this variant
    if order.user.present? and order.user.subscriptions.processable.exists?(variant: variant)
      return false
    end
    product.subscribable? && product.subscription_frequencies.any?
  end

  def subscription?
    !!subscription
  end

  def subscription
    order.subscriptions.find_by(variant: variant)
  end

  private

    def create_subscription!
      order.subscriptions.create! subscription_attributes
    end

    def subscription_attributes
      {
        subscription_frequency_id: product.subscription_frequencies.first.try(:id),
        price: variant.price,
        delivery_number: 9999,
        variant: variant,
        quantity: quantity
      }
    end

    def update_subscription_quantity
      subscription.update(quantity: quantity)
    end

    def update_subscription_attributes
      subscription.update(updatable_subscription_attributes)
    end

    def destroy_associated_subscription!
      subscription.destroy!
    end

    def can_update_subscription_attributes?
      subscription? && subscription_attributes_present?
    end

    def can_update_subscription_quantity?
      subscription? && quantity_changed?
    end

end
