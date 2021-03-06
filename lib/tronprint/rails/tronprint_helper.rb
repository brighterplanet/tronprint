require 'tronprint/statistics_formatter'
require 'timeout'

# Rails helper for displaying footprint data.
module TronprintHelper
  include Tronprint::StatisticsFormatter

  # The total amount of CO2e generated by the application.
  def total_footprint
    total_estimate.to_f
  end

  # The total amount of electricity used by the application.
  def total_electricity
    total_estimate.electricity_use.to_f
  end

  # A URL for the methodology statement of the emissions calculation.
  def footprint_methodology
    Tronprint.statistics.total_footprint_methodology
  end

  # An informational badge displaying total energy, footprint, CO2/minute
  def footprint_badge(options = {})
    text = nil
    if Tronprint.connected?
      begin
        footprint = pounds_with_precision total_estimate

        two_hr_emissions = Tronprint.statistics.
          emission_estimate(Time.now - 7200, Time.now).to_f
        rate = two_hr_emissions / 120  # kgs CO2 per minute over last 2 hours
        rate = rate < 0.0001 ? "< 0.0001" : pounds_with_precision(rate)

        text = <<-HTML
          <p class="tronprint-footprint">
            <span class="tronprint-total-footprint">
              <span class="tronprint-label">Total app footprint:</span>
              <span class="tronprint-value">#{total_electricity.to_i}</span>
              <span class="tronprint-units">W</span>,
              <span class="tronprint-value">#{footprint}</span>
              <span class="tronprint-units">lbs. CO<sub>2</sub>e</span>
            </span>
            <span class="tronprint-separator">&middot;</span>
            <span class="tronprint-current-footprint">
              <span class="tronprint-label">Current footprint:</span>
              <span class="tronprint-value">#{rate}</span>
              <span class="tronprint-units">lbs. CO<sub>2</sub>e/min.</span>
            </span>
            <span class="tronprint-attribution">#{tronprint_attribution if options[:attribution]}</span>
          </p>
        HTML
      rescue Timeout::Error => e
      rescue => e
      end
    end

    text ||= <<-HTML
      <p class="tronprint-footprint">App footprint unavailable</p>
    HTML

    text.html_safe
  end
  
  # Tronprint attribution
  def tronprint_attribution
    %q{App footprint calculated by <a href="http://brighterplanet.github.com/tronprint">Tronprint</a>}
  end

  # A link to more information about Tronprint
  def tronprint_badge
    %Q{<p class="tronprint-link">#{tronprint_attribution}</p>}.html_safe
  end

  # Let the world know that your app is powered by CM1
  def cm1_badge
    %q{<script type="text/javascript" src="http://impact.brighterplanet.com/badge.js"></script>}.
      html_safe
  end
  
  def total_estimate
    @total_estimate ||= Tronprint.statistics.emission_estimate
  end
end
