require 'pathname'
require 'csv'
# call python sk-learn lib from pip
ENV['PYTHON'] = 'python3' # use python3
require 'pycall/import'
include PyCall::Import
pyimport :numpy
pyfrom :'sklearn.linear_model', import: :LinearRegression
pyfrom :'sklearn.model_selection', import: :train_test_split
pyfrom :'sklearn.metrics', import: %i[mean_squared_error r2_score explained_variance_score]
pyimport :'matplotlib.pyplot', as: :plt

data = []
x = []
y = []
file = Pathname.pwd.join('data.csv')
puts "\nload data from #{file}"
CSV.foreach(file) do |row|
  data << row
  y << row[0].to_f
  x << row[1..-1].map(&:to_f)
end

x.first.size.times do |col|
  fig = plt.figure()
  x_data = x.map { |row| row[col] }
  y_data = y.map{ |row| row/100000000 }
  plt.scatter(x_data, y_data)
  plt.xlabel("x#{col}")
  plt.ylabel("actually power used")
  plt.title("actually power used vs x#{col}")
  fig.savefig("#{Pathname.pwd.join('result_images','actually power used vs x' + col.to_s)}")
end

results = []
# train 100 times to find the best linear regression formula
puts "\ntraining..."
workers = Array.new(100) do
  Thread.new do
    # split data to train data and test data
    x_train, x_test, y_train, y_test = train_test_split(x, y, test_size: 0.2)
    # run linear regression to find a formula for prediction
    lr = LinearRegression.new
    lr.fit(x_train, y_train)
    # testing
    y_pred = lr.predict(x_test)
    mean_squared_error_score = mean_squared_error(y_test, y_pred)
    variance_score = explained_variance_score(y_test, y_pred)
    r_squared_score = r2_score(y_test, y_pred)
    results << [lr, mean_squared_error_score, variance_score, r_squared_score]
  end
end
workers.each(&:join)

avg_mean_squared_error_score = results.map { |r| r[1].to_f }.sum / results.size
avg_variance_score = results.map { |r| r[2].to_f }.sum / results.size
avg_r_squared_score = results.map { |r| r[3].to_f }.sum / results.size
puts "\nthe average mean squared error: #{avg_mean_squared_error_score}"
puts "the average variance score: #{avg_variance_score}"
puts "the average r squared: #{avg_r_squared_score}"

puts "\nfinding the best linear regression formula..."
best_model =  results.max_by{ |a| a[3].to_f }
puts "the coefficients:"
best_model[0].coef_.size.times do |index|
  puts "\tx#{index}: #{best_model[0].coef_[index]}" # FIXME: pycall return array object is not a ruby Array, so can't use iterator
end
puts "the mean squared error: #{best_model[1]}"
puts "the variance score: #{best_model[2]}"
puts "the r squared: #{best_model[3]}"

fig = plt.figure()
plt.scatter(y, best_model[0].predict(x))
plt.plot(y, y)
plt.xlabel("actually power used")
plt.ylabel("power used prediction")
plt.title("actually power used vs power used_prediction")
fig.savefig("#{Pathname.pwd.join('result_images','actually_power_used_vs_power_used_prediction.png')}")

plt.show()
