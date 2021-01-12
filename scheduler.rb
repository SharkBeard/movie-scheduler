require 'tod'

class Theater
  attr_reader :hours, :clean, :previews, :showtime_increment

  def initialize(hours:, clean:, previews:, showtime_increment: 5) 
    @hours = {}
    hours.each do |type, schedule|
      @hours.store(type, {
        open: Tod::TimeOfDay.parse( schedule[:open] ), 
        close: Tod::TimeOfDay.parse( schedule[:close] ) 
      })
    end
    @clean = clean * 60
    @previews = previews * 60
    @showtime_increment = showtime_increment
  end
end

class Movie
  attr_reader :runtime, :title

  def initialize(text)
    parsed = parse(text)

    @runtime = parsed[:runtime]
    @title = parsed[:title]
  end

  def parse(text)
    parts = text.split('|')
    { runtime: parts[1].to_i, title: parts[0] }
  end
end

class Scheduler
  def initialize(theater:)
    @theater = theater
  end

  def round_down(time, minutes)
    time - (time.to_i % (minutes * 60))
  end

  def schedule(movie:)
    runtime = movie.runtime * 60

    showtimes = Hash.new
    @theater.hours.each do |schedule_type, hours|
      showings = []
      time = round_down(hours[:close] - runtime, @theater.showtime_increment)
      while (time >= hours[:open]) do
        showings.unshift(time) if (time - @theater.previews) > hours[:open]
        time = round_down(time - runtime - @theater.clean - @theater.previews, @theater.showtime_increment)
      end
      showtimes.store(schedule_type, showings)
    end
    showtimes
  end
end

hours = { weekday: { open: '11:00am', close: '11:00pm' }, weekend: { open: '10:30', close: '12:00am' } }
theater = Theater.new(hours: hours, clean: 20, previews: 15)

movie = Movie.new('Liar Liar | 86')
scheduler = Scheduler.new(theater: theater)

schedule = scheduler.schedule(movie: movie)
schedule.each do |type, showtimes|
  puts type.to_s
  showtimes.each do |showtime|
    endtime = showtime + (movie.runtime * 60)
    puts "#{showtime.to_s(:short)} - #{endtime.to_s(:short)}"
  end
  puts ''
end
