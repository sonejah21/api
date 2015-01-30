class OrderItem < ActiveRecord::Base
  acts_as_paranoid

  before_create :load_order_item_params

  after_commit :provision, on: :create

  belongs_to :order
  belongs_to :product
  belongs_to :cloud
  belongs_to :project

  enum provision_status: { ok: 0, warning: 1, critical: 2, unknown: 3, pending: 4 }

  validates :product, presence: true
  validate :validate_product_id

  private

  def validate_product_id
    errors.add(:product, 'Product does not exist.') unless Product.exists?(product_id)
  end

  def load_order_item_params
    self.hourly_price = product.hourly_price
    self.monthly_price = product.monthly_price
    self.setup_price = product.setup_price
  end

  def provision
    # Calling save inside an after_commit on: :create triggers a :create callback again.
    # Passed the object to the provision_order_item and called the save there.
    # https://github.com/rails/rails/issues/14493#issuecomment-39859373
    order_item = self

    order_item.delay(queue: 'provision_request').provision_order_item(order_item)
  end

  def provision_order_item(order_item)
    Delayed::Worker.logger.debug 'provision_order_item'
    @miq_settings = SettingField.where(setting_id: 2).order(load_order: :asc).as_json
    Delayed::Worker.logger.debug 'MIQ Settings'
    Delayed::Worker.logger.debug @miq_settings

    @message =
    {
      action: 'order',
      resource: {
        href: "#{@miq_settings[0]['value']}/api/service_templates/#{order_item.product.service_type_id}",
        id: order_item.id,
        uuid: order_item.uuid.to_s,
        product_details: order_item_details(order_item)
      }
    }
    Delayed::Worker.logger.debug 'Message Payload'
    Delayed::Worker.logger.debug @message

    order_item.provision_status = :unknown
    order_item.payload_to_miq = @message.to_json
    order_item.save

    # TODO: verify_ssl needs to be changed, this is the only way I could get it to work in development.
    @resource = RestClient::Resource.new(
        @miq_settings[0]['value'],
        user: @miq_settings[1]['value'],
        password: @miq_settings[2]['value'],
        verify_ssl: OpenSSL::SSL::VERIFY_NONE
    )
    Delayed::Worker.logger.debug 'RESTClient Resource'
    Delayed::Worker.logger.debug @resource

    handle_response(order_item)
  end

  def handle_response(order_item)
    Delayed::Worker.logger.debug 'handle_response'
    Delayed::Worker.logger.debug 'OrderItem'
    Delayed::Worker.logger.debug order_item
    begin
      @response = @resource["api/service_catalogs/#{order_item.product.service_catalog_id}/service_templates"].post @message.to_json, content_type: 'application/json'

      data = ActiveSupport::JSON.decode(@response)
      Delayed::Worker.logger.debug 'Data'
      Delayed::Worker.logger.debug data
      order_item.payload_reply_from_miq = data.to_json
      case @response.code
      when 200..299
        order_item.provision_status = :pending
        order_item.miq_id = data['results'][0]['id']
      when 400..499
        order_item.provision_status = :critical
      else
        order_item.provision_status = :warning
      end
    rescue => e
      Delayed::Worker.logger.debug 'Rescue Response!'
      Delayed::Worker.logger.debug @response
      @response = e.response
      order_item.provision_status = :unknown
      order_item.payload_reply_from_miq = { 'error' => 'Action response was out of bounds, or something happened that wasn\'t expected' }.to_json
    end

    order_item.save
    order_item.to_json
  end

  def order_item_details(order_item)
    Delayed::Worker.logger.debug 'order_item_details'
    details = {}

    answers = order_item.product.answers
    Delayed::Worker.logger.debug 'Answers'
    Delayed::Worker.logger.debug answers
    order_item.product.product_type.questions.each do |question|
      answer = answers.select { |row| row.product_type_question_id == question.id }.first
      Delayed::Worker.logger.debug 'Answer'
      Delayed::Worker.logger.debug answer
      Delayed::Worker.logger.debug 'Question'
      Delayed::Worker.logger.debug question
      details[question.manageiq_key] = answer.nil? ? question.default : answer.answer
    end

    Delayed::Worker.logger.debug 'Details'
    Delayed::Worker.logger.debug details
    details
  end
end
