class ApplicationController < ActionController::Base
  protect_from_forgery

  helper :all

  before_filter :authenticate_user!,
    :get_bitcoin_client,
    :move_xml_params,
    :set_locale,
    :set_time_zone

  def get_bitcoin_client
    @bitcoin = Bitcoin::Client.new
  end

  def set_time_zone
    if current_user and !current_user.time_zone.blank?
      Time.zone = ActiveSupport::TimeZone[current_user.time_zone]
    end
  end

#  # Changes the locale if *locale* (en|fr|...) is passed as GET parameter
#  def set_locale
#    # TODO : Try to guess locale with IP lookup and/or HTTP headers
#    locale = params[:locale] or session[:locale] or "en"
#    locale = locale.to_sym if locale
#
#    if locale and I18n.available_locales.include?(locale)
#      I18n.locale = locale
#      session[:locale] = locale
#    end
#  end
protected

  def set_locale
    @current_locale = extract_locale_from_subdomain
    I18n.locale = @current_locale

  end


  # Get locale code from request subdomain (like http://it.application.local:3000)
  # You have to put something like:
  #   127.0.0.1 gr.application.local ATTENTION PAS gr.local !!!!!!!!!!!!!!!
  # in your /etc/hosts file to try this out locally

  def extract_locale_from_subdomain
    parsed_locale = request.subdomains.empty? ? nil : request.subdomains.first.to_sym
    return parsed_locale if I18n.available_locales.include?(parsed_locale) # explicit language definition

    parsed_locale = extract_locale_from_header(I18n.available_locales)     # works excellent for localized browsers
    return parsed_locale unless parsed_locale.nil?

    return I18n.default_locale                                             # default language
  end


  def extract_locale_from_header(langs)
    # return nil or best match of given langs (as symbols, e.g. [:en, :ru, :ch])

    return nil if request.env["HTTP_ACCEPT_LANGUAGE"].nil?      # cannot detect language

    accepted = request.env["HTTP_ACCEPT_LANGUAGE"].split(/,/)   # comma-separated values, e.g. "ch,en,en-US"
    accepted = accepted.map { |l| l.strip.split(/\s*;\s*/) }    # each value have weight, e.g. "en-US;q=0.3"
    accepted = accepted.map do |l|
      [  l[0].split('-')[0].downcase.to_sym,                    # each language can have dialect, e.g. "en-US"
        l.length == 1 ? 1.0 : l[1].sub(/^q=\s*/, '').to_f      # default q is "1.0" (if missing)
      ]
    end

    accepted = accepted.select {|l| l if langs.include?(l[0])}  # remove unsupported languages

    return nil if accepted.empty?                               # no languages supported

    accepted.sort! { |l1, l2| l2[1] <=> l1[1] }                 # sort by quality (weight) descending

    return accepted.first[0]
  end

  

  def change_lang
    if params[:return_url]
      redirect_to(params[:return_url] || account_trade_orders_path)
    else
      redirect_to( account_trade_orders_path )
    end
  end

  
  # This method is used to work around the fact that there is only
  # one allowed root node in a well formed XML document, we remove
  # the root node so we get to pretend that XML === JSON
  def move_xml_params
    if request.content_type =~ /xml/
      params.merge! params.delete(:api)
    end
  end
end
