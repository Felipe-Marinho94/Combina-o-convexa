#Fun��o para a realiza��o da regress�o por combina��o convexa
#Autor: Felipe Pinto Marinho
#Data: 15/03/2022

#Carregando alguma bibliotecas importantes
library(plm)
library(pracma)
library(MASS)

######################################################
#Obten��o da Matriz C (1026 x 1026)
X_treino = Boston_treino_normalizado
V = t(X_treino)
LI = V

for (j in 1:ncol(V)) {
  if(is.numeric(detect.lindep(LI, suppressPrint = T)) == TRUE){
    LI = LI[, -detect.lindep(LI, suppressPrint = T)]
  }
  
  if(is.numeric(detect.lindep(LI, suppressPrint = T)) == FALSE){
    break()
  }
  
}

#Obten��o da base ortonormal
Q = gramSchmidt(t(LI))
Q = Q$Q

#Obten��o das coordenadas de observa��o de treinamento
C = matrix(0, nrow = nrow(X_treino), ncol = nrow(Q))
for (i in 1:nrow(C)) {
  for (j in 1:ncol(C)) {
    C[i, j] = dot(as.matrix(X_treino[i,]), Q[j,])
  }
}

##########################################################
#Fun��o para a regress�o por combina��o convexa
RCC = function(X_treino, x_teste, Y_treino, Y_teste){
  
  #Para uma nova observa��o qual ser� a observa��o de
  #treinamento mais similar pelas coordenadas
  
  #Determina��o das coordenadas
  D = rep(0, ncol(C))
  for (i in 1:nrow(C)) {
    D[i] = dot(as.matrix(x_teste), Q[i,])
  }
  
  #Determina��o do yM e yN
  S = rep(0, ncol(C))
  for (i in 1:nrow(X_treino)){
    S[i] = dot(D, C[i,])
  }
  
  yN = Y_treino[which.max(S)]
  yM =Y_treino[which.max(S[-which.max(S)])]
  y_media = mean(Y_treino)
  
  #Estimativa de theta
  #Fun��o objetivo
  objetivo = function(theta){
    return((theta*(yN-yM) + yM)^(2)*nrow(X_treino) - 2*(theta * (yN-yM) + yM)*sum(Y_treino) + dot(as.vector(Y_treino),as.vector(Y_treino)))
  }
  
  #Esta fun��o � de uma �nica vari�vel theta, com theta limitado ao intervalo
  #[0,1], ent�o para determinar seu m�nimo utiliza-se o teorema do intervalo fechado
  #Seus pontos cr�ticos s�o dados por
  NC = (y_media-yM)/(yN-yM)
  
  #Avalia��o do valor da fun��o no ponto cr�tico
  #e nos extremos do intervalo
  if (is.finite(NC)){
    if (objetivo(0) < objetivo(NC) & objetivo(0) < objetivo(1)){
      theta_hat = 0
    }
    
    if (objetivo(NC) < objetivo(0) & objetivo(NC) < objetivo(1)){
      theta_hat = NC
    }
    
    if (objetivo(1) < objetivo(0) & objetivo(1) < objetivo(NC)){
      theta_hat = 1
    }
  } else{
    if (objetivo(0) < objetivo(1)){
      theta_hat = 0
    } else{
      theta_hat = 1
    }
  }
  
  #Estimativa da sa�da
  y_hat = theta_hat * yN + (1-theta_hat) * yM
  return(y_hat)
}

#######################################################
#Avalia��o do desempenho
metricas = function(Y_estimado, Y_real){
  RMSE=sqrt(mean((Y_real-Y_estimado)^2))
  print(RMSE)
  SSE=sum((Y_real-Y_estimado)^2)
  SSTO=sum((Y_real-mean(Y_real))^2)
  R_squared=1-(SSE/SSTO)
  print(R_squared)
}

#######################################################
#Obten��o das estimativas para o conjunto de teste
Y_estimado = rep(0, length(Rad_teste))
Dados_1_teste = Dados_1[-treino, ]

#Pr�-processamento dos dados
Dados_1_normalizado = apply(Dados_1, 2, scale)
Dados_1_treino_normalizado = Dados_1_normalizado[treino, ]
Dados_1_teste_normalizado = Dados_1_normalizado[-treino, ]
Rad_treino_normalizado = scale(Rad_treino)
Rad_teste_normalizado = scale(Rad_teste)

for (k in 1:length(Rad_teste)){
  Y_estimado[k] = RCC(Dados_1_treino_normalizado, Dados_1_teste_normalizado[k, ], Rad_treino_normalizado, Rad_teste_normalizado)
}

Y_estimado = Y_estimado * sd(Rad_teste) + mean(Rad_teste)
metricas(Y_estimado, Rad_teste)

#Testando no conjunto de dados Boston
treino_Boston = sample(nrow(Boston), 0.7*nrow(Boston))
Boston_normalizado = apply(Boston, 2, scale)
Boston_treino_normalizado = Boston_normalizado[treino_Boston, ]
Boston_teste_normalizado = Boston_normalizado[-treino_Boston, ]
medv_treino_normalizado = scale(Boston$medv[treino_Boston])
medv_teste_normalizado = scale(Boston$medv[-treino_Boston])
Y_estimado_Boston = rep(0, nrow(medv_teste_normalizado))

for (k in 1:nrow(medv_teste_normalizado)){
  Y_estimado_Boston[k] = RCC(Boston_treino_normalizado, Boston_teste_normalizado[k, ], medv_treino_normalizado, medv_teste_normalizado)
}

Y_estimado = Y_estimado_Boston * sd(Boston$medv) + mean(Boston$medv)
metricas(Y_estimado, Boston$medv[-treino_Boston])

linear = lm(Dados_1_treino$H_30~., data = Dados_1_treino)
Y_estimado_Linear = predict(linear, Dados_1_teste)
metricas(Y_estimado_Linear, Rad_teste)
