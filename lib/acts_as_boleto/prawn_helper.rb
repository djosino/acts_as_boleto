module Prawn::Graphics
   # E.g. stroke_dashed_horizontal_line(0, 5.cm, :at => 10.cm, :line_length => 1.cm, :space_length => 1.mm)
   # Currently rounds up line/space periods: 1 cm line length + 1 mm space as a 3 cm line would be "- - -", 3.2 cm total.
   def stroke_dashed_horizontal_line(x1,x2,options={})
      options = options.dup
      line_length = options.delete(:line_length) || 0.5.mm
      space_length = options.delete(:space_length) || line_length
      period_length = line_length + space_length
      total_length = x2 - x1
       
      (total_length/period_length).ceil.times do |i|
         left_bound = x1 + i * period_length
         stroke_horizontal_line(left_bound, left_bound + line_length, options)
      end
   end
end
