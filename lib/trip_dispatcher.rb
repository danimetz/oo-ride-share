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

      private

      def check_id(id)
        raise ArgumentError, "ID cannot be blank or less than zero. (got #{id})" if id.nil? || id <= 0
      end

      def request_trip(user_id)
        # The user ID will be supplied (this is the person requesting a trip)
        # Your code should automatically assign a driver to the trip
        # For this initial version, choose the first driver whose status is :AVAILABLE
        # Your code should use the current time for the start time
        # The end date, cost and rating will all be nil
        # The trip hasn't finished yet!
      end
    end
  end



  # rideshare = RideShare::TripDispatcher.new('specs/test_data/users_test.csv','specs/test_data/trips_test.csv','specs/test_data/drivers_test.csv')
  #
  # puts rideshare.trips[0].driver.driven_trips
