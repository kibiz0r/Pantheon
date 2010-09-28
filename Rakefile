require 'rubygems'
require 'faster_csv'
require 'haml'
require 'ostruct'
require 'active_support/all'

task :default => [:'test:syntax', :'test:system']

namespace :test do
  task :syntax do
    sh 'mono NUnit/nunit-console.exe Pantheon.Syntax.Test/bin/Debug/Pantheon.Syntax.Test.dll'
  end

  task :system do
    sh 'mono NUnit/nunit-console.exe Pantheon.Test/bin/Debug/Pantheon.Test.dll'
  end
end

desc 'Generate a status report based on project data from Pivotal Tracker'
task :status_report, :iteration do |t, args|
  iteration = args[:iteration].to_i
  raise 'No iteration specified.' unless iteration

  start_date = '9/6/2010'.to_date
  end_date = '9/13/2010'.to_date

  iteration_start_date = start_date + iteration.weeks
  iteration_end_date = end_date + iteration.weeks

  all_stories = []
  expected_stories = []
  next_stories = []
  new_stories = []

  overview = Haml::Engine.new(File.read("StatusOverviews/#{iteration}.html.haml")).render

  FasterCSV.open "Pivotal/#{iteration}.csv", :headers => :first_row do |csv|
    csv.each do |row|
      story = OpenStruct.new :iteration => row['Iteration'].to_i,
        :title => row['Story'],
        :status => row['Current State'],
        :points => row['Estimate'].to_i,
        :created_at => row['Created at'].to_date

      all_stories << story

      if story.iteration == iteration
        expected_stories << story
      elsif story.iteration == iteration + 1
        next_stories << story
      end

      if story.created_at >= iteration_start_date and story.created_at <= iteration_end_date
        new_stories << story
      end
    end
  end

  velocity = 1.0 / 2.0 * (all_stories.select do |story| # change 1.0 / 1.0 to 1.0 / 2.0 for Iteration 2, 1.0 / 3.0 for Iteration 3, then leave it alone...
    story.status == 'accepted' and story.iteration > iteration - 3 and story.iteration <= iteration
  end.inject 0 do |memo, story|
    memo + story.points
  end)

  iteration_points_complete = expected_stories.select do |story|
    story.status == 'accepted'
  end.inject 0 do |memo, story|
    memo + story.points
  end

  iteration_points_defined = new_stories.inject 0 do |memo, story|
    memo + story.points
  end

  total_points_complete = all_stories.select do |story|
    story.status == 'accepted'
  end.inject 0 do |memo, story|
    memo + story.points
  end

  total_points_defined = all_stories.inject 0 do |memo, story|
    memo + story.points
  end

  template = File.read 'StatusReport.html.haml'
  engine = Haml::Engine.new template
  output = engine.render Object.new,
    :velocity => velocity,
    :iteration_points_complete => iteration_points_complete,
    :iteration_points_defined => iteration_points_defined,
    :total_points_complete => total_points_complete,
    :total_points_defined => total_points_defined,
    :iteration => iteration,
    :start_date => start_date,
    :end_date => end_date,
    :expected_stories => expected_stories,
    :next_stories => next_stories,
    :new_stories => new_stories,
    :overview => overview

  File.open "Iterations/#{iteration}.html", 'w' do |file|
    file.write output
  end
end
