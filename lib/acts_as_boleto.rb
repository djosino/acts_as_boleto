#require 'rubygems'
#require 'barby'
#require 'barby/barcode/code_25_interleaved'
#require 'barby/outputter/png_outputter'
#require 'prawn'
#require 'prawn/measurement_extensions'
path = File.dirname(__FILE__) + "/acts_as_boleto/"
["acts_as_boleto", "acts_as_boleto_helper"].each do |library|
   require path + library
end

ActionController::Base.send :include, ActsAsBoleto
ActionView::Base.send :include, ActsAsBoletoHelper