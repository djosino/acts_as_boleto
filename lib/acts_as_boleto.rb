path = File.dirname(__FILE__) + "/acts_as_boleto/"
[ "acts_as_boleto", "acts_as_boleto_helper"].each do |library|
   require path + library
end
ActionController::Base.send :include, ActsAsBoleto
ActionView::Base.send :include, ActsAsBoletoHelper