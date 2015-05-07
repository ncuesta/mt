require 'csv'
require 'json'
require 'active_support/all'
require 'bigdecimal'

today = if ARGV.size > 0
          Date.parse(ARGV[0])
        else
          Date.today
        end

data_path = './bills.csv'
categories_path = './categories.json'

class Bill
  attr_accessor :date, :amount

  def initialize(date = nil, amount = 0)
    self.date = date
    self.amount = amount
  end
end

class Category
  attr_accessor :name, :base, :upto, :cost

  def initialize(name, base, upto, cost)
    self.name = name
    self.base = base
    self.upto = upto
    self.cost = cost
  end
end

def load_bills(path)
  bills = []
  CSV.foreach(path) do |row|
    date = Date.parse(row.first)
    amount = BigDecimal.new(row.last)
    bills << Bill.new(date, amount)
  end
  bills
end

def load_categories(path)
  Hash[
    JSON.parse(File.read(path)).map do |name, data|
      [data['from']..data['to'], Category.new(name, data['from'], data['to'], data['cost'])]
    end
  ]
end

bills = load_bills(data_path)
categories = load_categories(categories_path)

a_year_ago = 1.year.ago(today) + 1.day
included_bills = bills.select { |b| b.date >= a_year_ago && b.date <= today }
total = included_bills.map(&:amount).inject(&:+)

puts "Total between %{start} and %{end}: %{total}" % { start: a_year_ago, end: today, total: total }
range_and_category = categories.select { |range, data| range.include? total }
category = range_and_category.first.last
puts "Category: %{name}, cost: $ %{cost} (still $ %{air} until the next category)" % { name: category.name, cost: category.cost, air: category.upto - total }
