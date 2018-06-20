class WeatherPower
  attr_accessor :date, :location, :kwh, :avg_t, :max_t, :min_t, :avg_rh,:rain_vol

  def initialize(date, location: '', kwh: 0, avg_t: nil, max_t: nil, min_t: nil, avg_rh: nil, rain_vol: nil)
    @date = date
    @location = location
    @kwh = kwh.to_f
    @avg_t = avg_t.to_f
    @max_t = max_t.to_f
    @min_t = min_t.to_f
    @avg_rh = avg_rh.to_f
    @rain_vol = rain_vol.to_f
  end

  def to_h
    {date: @date, location: @location, kwh: @kwh, avg_t: @avg_t, max_t: @max_t, min_t: @min_t, avg_rh: @avg_rh, rain_vol: @rain_vol}
  end

  def to_x
    [@avg_t, @max_t, @min_t, @avg_rh, @rain_vol]
  end

  def to_y
    Math.log10(@kwh)
  end

  def to_a
    [Math.log10(@kwh), @avg_t, @max_t, @min_t, @avg_rh, @rain_vol]
  end
end
