# Climance

Aplicativo de tempo feito com SwiftUI para consultar a temperatura atual em graus Celsius, pela localização do usuário ou pela busca de uma cidade. Disponível como projeto para iPhone, iPad e Mac.

## Funcionalidades

- **Agora:** mostra o local e a temperatura atual usando a localização do dispositivo, com atualização manual.
- **Buscar:** pesquisa cidades e permite escolher o local correto entre resultados com nomes semelhantes.
- Cartão de temperatura com cidade e horário da consulta.
- Toque em **Temperatura atual · Celsius/Fahrenheit** para alternar a unidade. A escolha vale para as duas telas e é mantida ao reabrir o app; a conversão é feita localmente.
- Estados de carregamento e mensagens para problemas de conexão, cidade não encontrada e localização indisponível.
- Liquid Glass nativo nos cartões e painéis no iOS/macOS 26 ou superior, com alternativa visual em versões anteriores.
- Aparência clara e escura, suporte a tamanhos de texto de acessibilidade e navegação nativa.
- Layout adaptável: abas em telas compactas e localização e busca lado a lado a partir de 620 pontos de largura. Com texto em tamanhos de acessibilidade, mantém as abas para priorizar a leitura.

A adaptação à largura foi pensada também para o iPhone Duo. Os resultados ficam preservados ao reorganizar as telas; a conferência visual da transição ao dobrar e desdobrar o dispositivo ainda está pendente.

## Requisitos

- Mac com Xcode e SDKs compatíveis com o destino escolhido.
- iOS/iPadOS 16.2 ou superior, ou macOS 12.7 ou superior, conforme configurado no projeto.
- Conexão com a internet para consultar os serviços de clima e localização de cidades.
- Para executar no iPhone Duo, use uma instalação do Xcode com o SDK e o simulador desse modelo.

## Como executar

1. Abra `Climance.xcodeproj` no Xcode.
2. Aguarde a resolução das dependências do Swift Package Manager.
3. Selecione o scheme **Climance** e um destino: **My Mac**, um simulador ou um dispositivo conectado.
4. Para um dispositivo físico, selecione seu time em **Signing & Capabilities** no target **Climance**, ajustando o Bundle Identifier se necessário.
5. Execute com **⌘R**.

Na primeira abertura, o aplicativo solicita permissão de localização. Se preferir negar, a busca manual por cidade continua disponível. No simulador, configure uma localização simulada para experimentar a tela **Agora**.

### Problemas comuns

- **Dependência não encontrada:** execute **File → Packages → Resolve Package Versions**. Se persistir, tente **Reset Package Caches** e **Product → Clean Build Folder**.
- **Localização indisponível:** confira a permissão do Climance e os Serviços de Localização nos ajustes do sistema. No simulador, confira também a localização simulada.
- **Erro de assinatura:** revise o time e o Bundle Identifier em **Signing & Capabilities**.

## Dados e privacidade

A busca de cidades usa a [API de geocodificação da Open-Meteo](https://open-meteo.com/en/docs/geocoding-api), baseada em dados do [GeoNames](https://www.geonames.org/). A temperatura usa a [API de previsão da Open-Meteo](https://open-meteo.com/en/docs), solicitando `current=temperature_2m` em Celsius.

A configuração atual não exige chave de API. Para uma distribuição comercial, consulte os [termos da Open-Meteo](https://open-meteo.com/en/terms) antes de definir a configuração de produção.

Quando a localização é autorizada, o Core Location obtém as coordenadas, o geocodificador da Apple identifica o local e as coordenadas são enviadas à Open-Meteo para consultar a temperatura. A busca manual envia o nome digitado ao serviço de geocodificação. O app não implementa rastreamento em segundo plano nem armazenamento persistente do histórico de consultas. A preferência de unidade de temperatura é salva localmente.

O horário exibido no cartão representa o momento da consulta, não o horário de uma medição feita por uma estação meteorológica.

## Organização do código

```text
Climance/
├── ClimanceApp.swift                         # Entrada do aplicativo
├── ContentView.swift                         # Navegação e layout adaptável
├── Climance.entitlements                     # Permissões do app para Mac
├── Data/Network/APIConstants.swift           # Serviço HTTP, modelos e erros
└── Presentation/
    ├── View/WeatherComponents.swift          # Componentes visuais reutilizáveis
    └── ViewModel/
        ├── LocalWeatherModel.swift           # Localização e temperatura local
        └── CitySearchModel.swift             # Busca, seleção e temperatura da cidade

ClimanceTests/                                # Testes do serviço de clima
ClimanceUITests/                              # Testes de interface
```

As chamadas HTTP utilizam `URLSession` e `async/await`. O projeto ainda inclui Alamofire como dependência, mas as consultas atuais não o utilizam.

## Testes

No Xcode, execute os testes com **⌘U**. Para executar somente os testes do serviço no Mac:

```sh
xcodebuild \
  -project Climance.xcodeproj \
  -scheme Climance \
  -destination 'platform=macOS' \
  -only-testing:ClimanceTests \
  test
```

Os testes do serviço usam respostas HTTP simuladas e verificam nomes com acentos, cidades distintas, busca vazia, cidade não encontrada, coordenadas da cidade selecionada e falhas do servidor, sem depender da API externa.

O teste de interface verifica a navegação e a preservação do texto da busca após mudanças de orientação. Ele não substitui a validação das telas aberta e fechada do Duo.

## Escopo atual

O Climance consulta a temperatura atual. Ainda não inclui previsão de vários dias, sensação térmica, chuva, favoritos ou funcionamento offline.
