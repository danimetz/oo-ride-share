require 'csv'
# require 'time'
require 'pry'
require 'awesome_print'

require_relative 'user'
require_relative 'trip'
require_relative 'driver'

module RideShare
  class TripDispatcher
    attr_reader :drivers, :passengers, :trips

    def initialize(user_file = 'support/users.csv',
      trip_file = 'support/trips.csv',
      driver_file = 'support/drivers.csv')
      @passengers = load_users(user_file)
      @drivers = load_drivers(driver_file)
      @trips = load_trips(trip_file)
    end

    def load_users(filename)
      users = []

      CSV.read(filename, headers: true).each do |line|
        input_data = {}
        input_data[:id] = line[0].to_i
        input_data[:name] = line[1]
        input_data[:phone] = line[2]

        users << User.new(input_data)
      end

      return users
    end


    def load_trips(filename)
      trips = []
      trip_data = CSV.open(filename, 'r', headers: true,
        header_converters: :symbol)

        trip_data.each do |raw_trip|
          passenger = find_passenger(raw_trip[:passenger_id].to_i)
          driver = find_driver(raw_trip[:driver_id].to_i)

          parsed_trip = {
            id: raw_trip[:id].to_i,
            driver: driver,
            passenger: passenger,
            start_time: Time.parse(raw_trip[:start_time]),
            end_time: Time.parse(raw_trip[:end_time]),
            cost: raw_trip[:cost].to_f,
            rating: raw_trip[:rating].to_i
          }
          #binding.pry
          trip = Trip.new(parsed_trip)
          passenger.add_trip(trip)
          driver.add_driven_trip(trip)
          trips << trip
        end
        return trips
      end

      def load_drivers(filename)
        drivers = []
        driver_data = CSV.open(filename, 'r', headers:true, header_converters: :symbol)
        driver_data.each do |raw_data|
          driver = find_passenger(raw_data[:id].to_i)
          parsed_driver = {
            id: raw_data[:id].to_i,
            vin: raw_data[:vin],
            status: raw_data[:status].to_sym,
            name: driver.name,
            phone: driver.phone,
          }
          driver = Driver.new(parsed_driver)
          drivers << driver

          @passengers.each_with_index do |user, index|
            if driver.id == user.id
              @passengers[index] = driver
            end
          end
        end
        return drivers
      end


      def find_passenger(id)
        check_id(id)
        return @passengers.find { |passenger| passenger.id == id }
      end

      def find_driver(id)
        check_id(id)
        return @drivers.find { |driver| driver.id == id }
      end


      def inspect
        return "#<#{self.class.name}:0x#{self.object_id.to_s(16)} \
        #{trips.count} trips, \
        #{drivers.count} drivers, \
        #{passengers.count} passengers>"
      end

      def available_driver
        if @drivers.find_all{|driver| driver.status == :AVAILABLE} == []
          raise ArgumentError.new("There are no available drivers at this time. Apologies.")
        else
          available_drivers = @drivers.find_all{|driver| driver.status == :AVAILABLE}
        end
        available_drivers.each do |driver|
          if driver.driven_trips == []
            return driver
          end
        end
        available_drivers = available_drivers.sort_by{|driver| driver.driven_trips.last.end_time}

        return available_drivers.first

      end

      def request_trip(user_id)
        # The user ID will be supplied (this is the person requesting a trip)
        @drivers.each do |driver|
          if driver.id == user_id && driver.status == :AVAILABLE
            driver.status = :UNAVAILABLE
          end
        end

        new_driver = self.available_driver
        new_passenger = self.find_passenger(user_id)

        parsed_trip = {
          id: (@trips.length) + 1,
          driver: new_driver,
          passenger: new_passenger,
          start_time: Time.new
        }

        in_progress_ride = Trip.new(parsed_trip)

        new_driver.status = :UNAVAILABLE
        new_driver.add_driven_trip(in_progress_ride)
        new_passenger.add_trip(in_progress_ride)

        @trips << in_progress_ride

        @drivers.each do |driver|
          if driver.id == user_id
            driver.status = :AVAILABLE
          end
        end

        return in_progress_ride

      end

      private

      def check_id(id)
        raise ArgumentError, "ID cannot be blank or less than zero. (got #{id})" if id.nil? || id <= 0
      end
    end
  end
