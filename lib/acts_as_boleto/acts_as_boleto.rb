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
  end
end
