module ActsAsBoleto

  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def acts_as_boleto
      extend ActsAsBoleto::SingletonMethods
      include ActsAsBoleto::InstanceMethods
    end
  end

  module SingletonMethods
  end

  module InstanceMethods
    def gera_boleto
        @dadosboleto = session[:dadosboleto] if session[:dadosboleto]
        @codigobanco = @dadosboleto[:banco]
        @codigo_banco_com_dv = @dadosboleto[:codigo_banco_com_dv] = gera_codigo_banco(@codigobanco)
        @nummoeda = "9"
        @fator_vencimento = fator_vencimento(@dadosboleto[:data_vencimento])

        #valor tem 10 digitos, sem virgula
        @valor = formata_numero(@dadosboleto[:valor_boleto],10,0,"valor")
        #agencia é 4 digitos
        @agencia = formata_numero(@dadosboleto[:agencia],4,0)
        #conta é 6 digitos
        @conta = formata_numero(@dadosboleto[:conta],6,0)
        #dv da conta
        @conta_dv = formata_numero(@dadosboleto[:conta_dv],1,0)
        #carteira é 2 caracteres
        @carteira = @dadosboleto[:carteira]

        #nosso número (sem dv) é 11 digitos
        @nnum = formata_numero(@dadosboleto[:carteira],2,0) + formata_numero(@dadosboleto[:nosso_numero],11,0)
        #dv do nosso número
        @dv_nosso_numero = digito_verificador_nossonumero(@nnum)

        #conta cedente (sem dv) é 7 digitos
        @conta_cedente = formata_numero(@dadosboleto[:conta_cedente],7,0)
        #dv da conta cedente
        @conta_cedente_dv = formata_numero(@dadosboleto[:conta_cedente_dv],1,0)

        #$ag_contacedente = $agencia . $conta_cedente;

        # 43 numeros para o calculo do digito verificador do codigo de barras
        @dv = digito_verificador_barra("#{@codigobanco}#{@nummoeda}#{@fator_vencimento}#{@valor}#{@agencia}#{@nnum}#{@conta_cedente}0")
        # Numero para o codigo de barras com 44 digitos
        @linha = "#{@codigobanco}#{@nummoeda}#{@dv}#{@fator_vencimento}#{@valor}#{@agencia}#{@nnum}#{@conta_cedente}0"

        @nossonumero = "#{@nnum[0,2]}/#{@nnum[2,(@nnum.size - 1)]}-#{@dv_nosso_numero}"
        @agencia_codigo = "#{@agencia}-#{@dadosboleto[:agencia_dv]} / #{@conta_cedente}-#{@conta_cedente_dv}"


        @dadosboleto[:codigo_barras] = @linha
        @dadosboleto[:linha_digitavel] = monta_linha_digitavel(@linha)
        @dadosboleto[:agencia_codigo] = @agencia_codigo
        @dadosboleto[:nosso_numero] = @nossonumero
    end

    #Fator vencimento, phpboleto
    def fator_vencimento(data)
        data_base = '1997/10/07'.to_date
        (data).to_date - data_base
        #(Time.today + 1.day).to_date - data_base
    end

    def digito_verificador_nossonumero(numero)
      resto2 = modulo_11(numero, 7, 1)
      digito = 11 - resto2
      if (digito == 10)
         dv = "P"
      elsif(digito == 11)
        dv = 0
            else
        dv = digito
      end
      return dv
    end


    def digito_verificador_barra(numero)
      resto2 = modulo_11(numero, 9, 1)
      if (resto2 == 0 || resto2 == 1 || resto2 == 10)
        dv = 1
      else
        dv = 11 - resto2
      end
      return dv
    end

    #retira as virgulas
    #formata o numero
    #preenche com zeros
    def formata_numero(numero,loop,insert,tipo = "geral")
      if (tipo == "geral")
        numero = numero.gsub(',','')
        while(numero.size<loop) do
            numero = "#{insert}#{numero}"
        end
      end
      if (tipo == "valor")
        numero = numero.to_s.gsub(',','')
        numero = numero.gsub('.','')
        while(numero.size<loop) do
          numero = "#{insert}#{numero}"
        end
      end
      if (tipo == "convenio")
        while(numero.size<loop)do
          numero = "#{numero}#{insert}"
        end
      end
      return numero
    end

    #modulo 10 retirada do phpBoleto
    def modulo_10(num)
      numtotal10 = 0
      fator = 2
      numeros = []
      parcial10 = []
      numtotal10 = 0

      for i in (1..num.size).to_a.reverse
        numeros[i] = num[i-1,1].to_i
        temp = numeros[i].to_i * fator
        temp0=0
        temp.to_s.split("").each { |j| temp0 += j.to_i }
        parcial10[i] = temp0.to_i
        numtotal10 += parcial10[i].to_i
        if fator == 2
          fator = 1
        else
          fator = 2
        end
      end
      resto = numtotal10 % 10
      digito = 10 - resto
      if (resto == 0)
         digito = 0
      end
      return digito
    end

    def modulo_11(num,base=9,r=0)
      soma = 0
      fator = 2

      numeros = []
      parcial = []
      for i in (1..num.size).to_a.reverse
          numeros[i] = num[i-1,1].to_i
          parcial[i] = numeros[i] * fator
          soma += parcial[i].to_i
          if (fator == base)
              fator = 1
          end
          fator += 1
      end
      if (r == 0)
          soma *= 10
          digito = soma % 11
          if (digito == 10)
              digito = 0
          end
          return digito
      elsif (r == 1)
          resto = soma % 11
          return resto
      end
    end

    def f_moeda(v)
      p,c = v.to_s.split(".")
      i = 1
      pos = 1
      while i < ( (v.to_s.length - 1)/3) and pos > 0
        p.insert(p.length - ((3 * i) + (i - 1)),".")
        i += 1
      end
      c = c + '0' if (c.length < 2 and c.to_i < 10)
      p + ',' + c
   end


    def monta_linha_digitavel(linha)
        # 01-03    -> Código do banco sem o digito
        # 04-04    -> Código da Moeda (9-Real)
        # 05-05    -> Dígito verificador do código de barras
        # 06-09    -> Fator de vencimento
        # 10-19    -> Valor Nominal do Título
        # 20-44    -> Campo Livre (Abaixo)

        # 20-23    -> Código da Agencia (sem dígito)
        # 24-05    -> Número da Carteira
        # 26-36    -> Nosso Número (sem dígito)
        # 37-43    -> Conta do Cedente (sem dígito)
        # 44-44    -> Zero (Fixo)


        # 1. Campo - composto pelo código do banco, código da moéda, as cinco primeiras posições
        # do campo livre e DV (modulo10) deste campo

        p1 = linha[0, 4]                                                                  # Numero do banco + Carteira
        p2 = linha[19, 5]                                                         # 5 primeiras posições do campo livre

        p3 = modulo_10("#{p1}#{p2}")                                            # Digito do campo 1
        p4 = "#{p1}#{p2}#{p3}"                                                          # União
        campo1 = "#{p4[0, 5]}.#{p4[5,p4.size]}"    #TODO: conferir o substring(texto,5)

        # 2. Campo - composto pelas posiçoes 6 a 15 do campo livre
        # e livre e DV (modulo10) deste campo
        p1 = linha[24, 10]                                      #Posições de 6 a 15 do campo livre
        p2 = modulo_10(p1)                                                              #Digito do campo 2
        p3 = "#{p1}#{p2}"
        campo2 = "#{p3[0, 5]}.#{p3[5,p3.size]}"      #TODO: conferir o substring(texto,5)

        # 3. Campo composto pelas posicoes 16 a 25 do campo livre
        # e livre e DV (modulo10) deste campo
        p1 = linha[34, 10]                                              #Posições de 16 a 25 do campo livre
        p2 = modulo_10(p1)                                                              #Digito do Campo 3
        p3 = "#{p1}#{p2}"
        campo3 = "#{p3[0, 5]}.#{p3[5,p3.size]}"     #TODO: conferir o substring(texto,5)

        # 4. Campo - digito verificador do codigo de barras
        campo4 = linha[4, 1]

        # 5. Campo composto pelo fator vencimento e valor nominal do documento, sem
        # indicacao de zeros a esquerda e sem edicao (sem ponto e virgula). Quando se
        # tratar de valor zerado, a representacao deve ser 000 (tres zeros).
                    p1 = linha[5, 4]
                    p2 = linha[9, 10]
                    campo5 = "#{p1}#{p2}"
        return "#{campo1} #{campo2} #{campo3} #{campo4} #{campo5}"
    end

    def gera_codigo_banco(numero)
        parte1 = numero.to_s[0,3]
        parte2 = modulo_11(parte1)
        return "#{parte1}-#{parte2}"
    end

    
    def fbarcode_prawn(valor, nome)
      barcode = Barby::Code25Interleaved.new(valor)
      File.open(Rails.root + "/tmp/cache/#{nome}.png", 'w'){|f|
        f.write barcode.to_png(:height => 50, :margin => 0)
      }
    end  

    def render_prawn(dadosboleto, boleto)
      font_size = 9
      tfont_size= 8
      ##      
      barcode = Barby::Code25Interleaved.new(dadosboleto[:codigo_barras])
      File.open(Rails.root + "/tmp/cache/#{boleto.id}.png", 'w'){|f|
        f.write barcode.to_png(:height => 50, :margin => 0)
      }
      ##
      table_opts = {:size => tfont_size, :inline_format => true, :padding => 3, :height => 27} 
      table_opts_no_top = table_opts.merge({:borders => [:left, :right, :bottom]})

      Prawn::Document.generate(Rails.root + "/public/boletos/#{boleto.id}.pdf", 
                               :page_layout => :portrait, 
                               :left_margin   => 0.5.cm,
                               :right_margin  => 1.cm,
                               :top_margin    => 1.cm,
                               :bottom_margin => 1.cm,
                               :page_size     => 'A4') do
         # TOPO
         #cell :x => 5, :y => 790, :width => 410, :height => 770, :border_width => 0.2, :padding_top => -1.5
         text_box "Instruções de Impressão", :size => font_size, :style => :bold, :at => [0, cursor], :width => 535, :align => :center
         move_down 15
         text_box "• Imprima em impressora jato de tinta (ink jet) ou laser em qualidade normal ou alta (Não use modo econômico).    \n" +
                  "• Utilize folha A4 (210 x 297 mm) ou Carta (216 x 279 mm) e margens mínimas à esquerda e à direita do formulário. \n" +
                  "• Corte na linha indicada. Não rasure, risque, fure ou dobre a região onde se encontra o código de barras.        \n" +
                  "• Caso não apareça o código de barras no final, clique em F5 para atualizar esta tela. \n" +
                  "• Caso tenha problemas ao imprimir, copie a sequencia numérica abaixo e pague no caixa eletrônico ou internet banking:", :size => font_size, :style => :bold, :at => [5, cursor], :leading => 2.5, :width => 535

         move_down 75
         text_box "Linha Digitável: #{dadosboleto[:linha_digitavel]}", :size => font_size +1, :style => :bold, :at => [5, cursor]
         move_down 15
         text_box "Valor: R$ #{dadosboleto[:valor_boleto]}",           :size => font_size +1, :style => :bold, :at => [5, cursor]
         if boleto.financiado and boleto.financiado.domicilio 
            origem = boleto.financiado.domicilio.cod == '1389' ? "CAPITAL" : "INTERIOR"
            text_box "ORIGEM: #{origem}",                             :size => font_size + 1, :style => :bold, :at => [150, cursor]
         end
         text_box "PLACA: #{boleto.placa}",                           :size => font_size + 1, :style => :bold, :at => [280, cursor]

         move_down 25
         # linha 1
         stroke_dashed_horizontal_line(0,535, :at => cursor)
         move_down 4
         text_box "Recibo do Sacado",                                 :size => 8, :at => [466, cursor]
         # Fim TOPO

         # 
         move_down 30
         image "#{Rails.root}/public/images/logobradesco.jpg", :at => [0, cursor], :width => 80
         line([135,cursor ],[135,cursor - 20])
         stroke
         line([185,cursor ],[185,cursor - 20])
         stroke
         move_down 5
         text_box dadosboleto[:codigo_banco_com_dv], :style => :bold, :size => font_size + 6, :at => [140, cursor]
         move_down 5
         text_box dadosboleto[:linha_digitavel],     :style => :bold, :size => font_size + 2, :at => [220, cursor]
         # 


         # Tabela 1 - Linha 1
            montar_linha = [
                       ["Cedente \n       <b> #{dadosboleto[:cedente]}        </b>", 200 ],
                       ["Agência/Código\n <b> #{dadosboleto[:agencia_codigo]} </b>", 100 ],
                       ["Espécie\n        <b> #{dadosboleto[:especie]}        </b>", 45  ],
                       ["Quantidade\n     <b> #{dadosboleto[:quantidade]}     </b>", 55  ],
                       ["Nosso Número\n  ", 130    ] 
                     ]
            move_down 10.6
            table([montar_linha.collect{|l| l[0]}], :column_widths => montar_linha.collect{|l| l[1]}, :cell_style => table_opts) 
            move_up 10
            text_box dadosboleto[:nosso_numero], :at => [0, cursor], :align => :right, :width => 525, :size => tfont_size, :style => :bold
            # fim Linha 1
            move_down 9.5
            # Tabela 1 - Linha 2
            montar_linha = [
                       ["Número do documento \n <b> #{dadosboleto[:numero_documento]} </b>", 200 ],
                       ["CPF/CNPJ            \n <b> #{dadosboleto[:cpf_cnpj]}         </b>", 100  ],
                       ["Vencimento          \n <b> #{dadosboleto[:data_vencimento]}  </b>", 100  ],
                       ["Valor documento     \n", 130 ]
                     ]
            move_down 0.5
            table([montar_linha.collect{|l| l[0]}], :column_widths => montar_linha.collect{|l| l[1]}, :cell_style => table_opts_no_top)  
            text_box dadosboleto[:data_vencimento], :at => [310, 624], :align => :right, :width => 95, :size => tfont_size, :style => :bold
            # fim Linha 2
            
            # Tabela 1 - Linha 3
            montar_linha = [
                       ["(-) Desconto / Abatimentos \n ", 115   ],
                       ["(-) Outras deduçõees\n        ", 95   ],
                       ["(+) Mora / Multa\n            ", 95 ],
                       ["(+) Outros acréscimos\n       ", 95 ],
                       ["(=) Valor cobrado\n           ", 130  ]
                     ]
            move_down 0.2
            table([montar_linha.collect{|l| l[0]}], :column_widths => montar_linha.collect{|l| l[1]}, :cell_style => table_opts) 
            # fim Linha 3
            
            # Tabela 1 - Linha 4
            montar_linha = [ ["Sacado \n <b> #{dadosboleto[:sacado]} </b>", 530 ]]          
            move_down 0.2
            table([montar_linha.collect{|l| l[0]}], :column_widths => montar_linha.collect{|l| l[1]}, :cell_style => table_opts)  
            # fim Linha 4

            move_down 5
            #rodape tabela 1
            text_box "Demonstrativo",         :size => 8, :at => [0,   cursor]
            text_box "Autenticação Mecânica", :size => 8, :at => [445, cursor]
            move_down 60
            text_box "Corte na linha pontilhada",:size => 8, :at => [440, cursor]
            move_down 8
            stroke_dashed_horizontal_line(0,535, :at => cursor)
            #fim rodape tabela 1
         # fim tabela 1
         move_down 10
         # 
         image "#{Rails.root}/public/images/logobradesco.jpg", :at => [0, cursor], :width => 80
         line([135,cursor ],[135,cursor - 20])
         stroke
         line([185,cursor ],[185,cursor - 20])
         stroke
         move_down 5
         text_box dadosboleto[:codigo_banco_com_dv], :style => :bold, :size => font_size + 6, :at => [140, cursor]
         move_down 5
         text_box dadosboleto[:linha_digitavel],     :style => :bold, :size => font_size + 2, :at => [220, cursor]
         # 
         # Tabela 2 - Linha 1
            montar_linha = [["Local de Pagamento \n <b> Pagável em qualquer Banco até o vencimento </b>", 400 ],
                            ["Vencimento\n          <b> </b>", 130  ]]
            move_down 10.6
            table([montar_linha.collect{|l| l[0]}], :column_widths => montar_linha.collect{|l| l[1]}, :cell_style => table_opts)  
            text_box dadosboleto[:data_vencimento], :at => [0, cursor + 10], :align => :right, :width => 525, :size => tfont_size, :style => :bold
            # fim Linha 1

            # Tabela 2 - Linha 2
            montar_linha = [["Cedente \n               <b> #{dadosboleto[:cedente]}        </b>", 400 ],
                            ["Agência/Código Cedente\n ", 130 ]]
            move_down 0.2
            table([montar_linha.collect{|l| l[0]}], :column_widths => montar_linha.collect{|l| l[1]}, :cell_style => table_opts_no_top) 
            text_box dadosboleto[:agencia_codigo], :at => [0, cursor + 10], :align => :right, :width => 525, :size => tfont_size, :style => :bold
            # fim Linha 2
            
            # Tabela 2 - Linha 3
            montar_linha = [["Data do Documento \n  <b> #{dadosboleto[:data_documento]}     </b>", 90 ],
                            ["Número do Documento\n <b> #{dadosboleto[:numero_documento]}   </b>", 100 ],
                            ["Espécie doc.\n        <b> #{dadosboleto[:especie_doc]}        </b>", 65 ],
                            ["Aceite\n              <b> #{dadosboleto[:aceite]}             </b>", 50 ],
                            ["Data Processamento\n  <b> #{dadosboleto[:data_documento]} </b>", 95 ],
                            ["Nosso Número\n        <b>  </b>", 130 ] ]
            move_down 0.2
            table([montar_linha.collect{|l| l[0]}], :column_widths => montar_linha.collect{|l| l[1]}, :cell_style => table_opts_no_top) 
            text_box dadosboleto[:nosso_numero], :at => [0, cursor + 10], :align => :right, :width => 525, :size => tfont_size, :style => :bold
            # fim Linha 3
            
            # Tabela 2 - Linha 4
            montar_linha = [["Uso do Banco       \n <b>   </b>", 70 ],
                            ["Carteira           \n <b> #{dadosboleto[:carteira]}       </b>", 65 ],
                            ["Espécie            \n <b> #{dadosboleto[:especie]}        </b>", 70 ],
                            ["Quantidade         \n <b> #{dadosboleto[:quantidade]}     </b>", 95 ],
                            ["Valor Documento    \n <b> #{dadosboleto[:valor_unitario]} </b>", 100 ],
                            ["(=) Valor Documento\n <b> </b>",  130 ] ]            
            move_down 0.2
            table([montar_linha.collect{|l| l[0]}], :column_widths => montar_linha.collect{|l| l[1]}, :cell_style => table_opts_no_top) 
            text_box dadosboleto[:valor_boleto], :at => [0, cursor + 10], :align => :right, :width => 525, :size => tfont_size, :style => :bold
            # fim Linha 4

            line([0,  cursor],[0, cursor - 135])
            stroke
            line([400,cursor],[400, cursor - 135])
            stroke
            line([530,cursor],[530, cursor - 135])
            stroke

            # Tabela 2 - Linha 5 coluna 1
            move_down 4
            text_box "Instruções (Texto de responsabilidade do cedente)",  :at => [5, cursor], :size => tfont_size
            move_down 60
            text_box dadosboleto[:instrucoes2], :at => [5, cursor], :size => tfont_size, :style => :bold
            move_down 15
            text_box dadosboleto[:instrucoes3], :at => [5, cursor], :size => tfont_size, :style => :bold
            # coluna 2
            move_up 75
            text_box "(-) Desconto / Abatimentos", :at => [405, cursor], :size => tfont_size
            move_down 22
            line([400,cursor],[530,cursor])
            stroke
            move_down 5
            text_box "(-) Outras deduções",        :at => [405, cursor], :size => tfont_size
            move_down 22
            line([400,cursor],[530,cursor])
            stroke
            move_down 5
            text_box "(+) Mora / Multa",           :at => [405, cursor], :size => tfont_size
            move_down 22
            line([400,cursor],[530,cursor])
            stroke
            move_down 5
            text_box "(+) Outros acréscimos",      :at => [405, cursor], :size => tfont_size
            move_down 22
            line([400,cursor],[530,cursor])
            stroke
            move_down 5
            text_box "(=) Valor cobrado",          :at => [405, cursor], :size => tfont_size


            
            # fim Linha 5

            # Tabela 2 - Linha 6
            montar_linha = [ ["Sacado \n <b> #{dadosboleto[:sacado]} </b>", 400 ],
                              ["Cód. baixa", 130]]
            move_down 23
            table([montar_linha.collect{|l| l[0]}], :column_widths => montar_linha.collect{|l| l[1]}, :cell_style => table_opts)  
            # fim Linha 6
            move_down 7
            #rodape tabela 1
            text_box "Sacador/Avalista",         :size => tfont_size, :at => [0,   cursor]
            text_box "Autenticação Mecânica - ", :size => tfont_size, :at => [348, cursor]
            text_box "Ficha de Compensação",     :size => tfont_size, :at => [438, cursor], :style => :bold
            move_down 15
            image "#{Rails.root}/tmp/cache/#{boleto.id}.png", :at => [0,cursor], :width => 270
            move_down 50
            text_box "Corte na linha pontilhada",:size => tfont_size - 0.5, :at => [0, cursor], :align => :right, :width => 525
            move_down 10
            stroke_dashed_horizontal_line(0,530, :at => cursor)
            #fim rodape tabela 1
         # fim tabela 2
       end
    end  
  end
end
