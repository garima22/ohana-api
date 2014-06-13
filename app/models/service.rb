class Service < ActiveRecord::Base
  attr_accessible :audience, :description, :eligibility, :fees,
                  :funding_sources, :keywords, :how_to_apply, :name,
                  :service_areas, :short_desc, :urls, :wait

  belongs_to :location, touch: true
  has_and_belongs_to_many :categories, -> { uniq }
  # has_many :schedules
  # accepts_nested_attributes_for :schedules

  validates :urls, array: {
    format: { with: %r{\Ahttps?://([^\s:@]+:[^\s:@]*@)?[A-Za-z\d\-]+(\.[A-Za-z\d\-]+)+\.?(:\d{1,5})?([\/?]\S*)?\z}i,
              message: '%{value} is not a valid URL' } }

  validate :service_area_format, if: (proc do |s|
    s.service_areas.is_a?(Array) && Settings.valid_service_areas.present?
  end)

  auto_strip_attributes :audience, :description, :eligibility, :fees,
                        :how_to_apply, :name, :short_desc, :wait, squish: true

  before_validation :strip_whitespace_from_each_keyword

  serialize :funding_sources, Array
  serialize :keywords, Array
  serialize :service_areas, Array
  serialize :urls, Array

  def service_area_format
    return unless service_areas.present?
    valid_service_areas = Settings.valid_service_areas
    return unless (service_areas - valid_service_areas).size != 0
    error_message = 'At least one service area is improperly formatted, ' \
      'or is not an accepted city or county name. Please make sure all ' \
      'words are capitalized.'
    errors.add(:service_areas, error_message)
  end

  def strip_whitespace_from_each_keyword
    return unless keywords.is_a?(Array)
    self.keywords = keywords.map(&:squish)
  end

  include Grape::Entity::DSL
  entity do
    expose :id
    expose :audience, unless: ->(o, _) { o.audience.blank? }
    expose :description, unless: ->(o, _) { o.description.blank? }
    expose :eligibility, unless: ->(o, _) { o.eligibility.blank? }
    expose :fees, unless: ->(o, _) { o.fees.blank? }
    expose :funding_sources, unless: ->(o, _) { o.funding_sources.blank? }
    expose :keywords, unless: ->(o, _) { o.keywords.blank? }
    expose :categories, using: Category::Entity, unless: ->(o, _) { o.categories.blank? }
    expose :how_to_apply, unless: ->(o, _) { o.how_to_apply.blank? }
    expose :name, unless: ->(o, _) { o.name.blank? }
    expose :service_areas, unless: ->(o, _) { o.service_areas.blank? }
    expose :short_desc, unless: ->(o, _) { o.short_desc.blank? }
    expose :urls, unless: ->(o, _) { o.urls.blank? }
    expose :wait, unless: ->(o, _) { o.wait.blank? }
    expose :updated_at
  end
end
