require 'sinatra'
require "sinatra/reloader" if development?
require 'active_record'
require 'pry'

configure :development, :production do
    ActiveRecord::Base.establish_connection(
       :adapter => 'sqlite3',
       :database =>  'db/dev.sqlite3.db'
     )
end

# Quick and dirty form for testing application
#
# If building a real application you should probably
# use views:
# http://www.sinatrarb.com/intro#Views%20/%20Templates
form = <<-eos
    <form id='myForm'>
        <input type='text' name="url">
        <input type="submit" value="Shorten">
    </form>
    <h2>Results:</h2>
    <h3 id="display"><a id='link'></a></h3>
    <script src="jquery.js"></script>

    <script type="text/javascript">
        $(function() {
            $('#myForm').submit(function() {
            $.post('/new', $("#myForm").serialize(), function(data){
                $('a#link').attr('href', data);
                $('a#link').html(data);
                });
            return false;
            });
    });
    </script>
eos

# through ActiveRecord.  Define
# associations here if need be
#
# http://guides.rubyonrails.org/association_basics.html
class Link < ActiveRecord::Base
    validates :url, :uniqueness => true
    before_save :add_http

    protected
    def add_http
        unless self.url.start_with? 'http://' then
            self.url = 'http://' + self.url
        end
    end

end

get '/' do
    form
end

get '/jquery.js' do
    send_file 'jquery.js'
end

get '/:id' do
    link = Link.find_by_id(params['id'])
    if link
        redirect link.url
    else
        status 404
    end
end

post '/new' do
    url = params['url']
    unless url.start_with? 'http://' then
        url = 'http://' + url
    end

    link = Link.new
    link.url = url
    link.save # generate id

    if link.errors then # assume is duplicate
        link = Link.find_by_url url
    end

    "http://localhost:4567/#{link.id}"
end

after do
  ActiveRecord::Base.connection.close
end
####################################################
####  Implement Routes to make the specs pass ######
####################################################
