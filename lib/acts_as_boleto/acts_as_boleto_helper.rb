module ActsAsBoletoHelper

  def esquerda(entra,comp)
    return entra[0,comp]
  end

  def direita(entra,comp)
    return entra[(entra.size-comp),(comp)]
  end

  def fbarcode(valor, imagem='local')
    fino = 1 
    largo = 3 
    altura = 50 
    barcodes = []
    barcodes[0] = "00110" 
    barcodes[1] = "10001" 
    barcodes[2] = "01001" 
    barcodes[3] = "11000" 
    barcodes[4] = "00101" 
    barcodes[5] = "10100" 
    barcodes[6] = "01100" 
    barcodes[7] = "00011" 
    barcodes[8] = "10010" 
    barcodes[9] = "01010" 
    
    
    
    for f1 in (0..9).to_a.reverse
      for f2 in (0..9).to_a.reverse
        f = (f1 * 10) + f2 
        texto = "" 
        for i in (1..5) 
          #texto +=  barcodes[f1][(i-1),1] + barcodes[f2][[i-1],1]
          j = i -1
          texto +=  barcodes[f1][j,1] + barcodes[f2][j,1]
        end
        barcodes[f] = texto
      end
    end


    #Guarda inicial
    img_path = '/images'                       if imagem == 'local' 
    img_path = "#{Rails.root}/public/images" if imagem == 'pdf'  

    desenho_barra = "<img src=#{img_path}/p.gif width=#{fino} height=#{altura} border=0>"
    desenho_barra += "<img src=#{img_path}/b.gif width=#{fino} height=#{altura} border=0>"
    desenho_barra += "<img src=#{img_path}/p.gif width=#{fino} height=#{altura} border=0>"
    desenho_barra += "<img src=#{img_path}/b.gif width=#{fino} height=#{altura} border=0><img "
      
    texto = valor

    if not ((texto.size % 2) == 0)
      texto = "0" + texto
    end

    #  Draw dos dados
    while texto.size > 0
      i = esquerda(texto,2).to_i
      texto = direita(texto,texto.size-2)
      f = barcodes[i]
      x = []
      (1..10).to_a.each { |i| x << i if not (i % 2) == 0 }
      for i in x
        if f[(i-1),1] == "0"
          f1 = fino 
        else
          f1 = largo
        end

        desenho_barra += "src=#{img_path}/p.gif width=#{f1} height=#{altura} border=0><img "
    
        if f[i,1] == "0"
          f2 = fino
        else
          f2 = largo
        end

        desenho_barra += "src=#{img_path}/b.gif width=#{f2} height=#{altura} border=0><img " 

      end
    end

    # Draw guarda final
    desenho_barra += "src=#{img_path}/p.gif width=#{largo} height=#{altura} border=0><img "
    desenho_barra += "src=#{img_path}/b.gif width=#{fino} height=#{altura} border=0><img " 
    desenho_barra += "src=#{img_path}/p.gif width=#{1} height=#{altura} border=0>"
    #session[:barra] = desenho_barra
    return desenho_barra
  end  

  
end
