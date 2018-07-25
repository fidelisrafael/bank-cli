## Bank

### Introdução

A implementação sugerida busca uma implementação bem simples, porém a implementação que eu estou enviando ficou um pouco mais completa, com uma arquitetura bem elaborada separando as camadas de **API**(não confudir com WebAPI) e de **CLI**, para que ambas sejam extendidas e testadas de formas isoladas.
Seria possível também implementar facilmente a interface WebAPI utilizando a `API` como fonte de dados e validações, porém não implementei.

É importante citar que desenvolvi **coisas extras** que poderiam ter sido simplificadas(como por exemplo camada de dadas), utilizando o **Sequel** ou mesmo **ActiveRecord**, porém eu aproveitei a oportunidade para trabalhar SOMENTE com a standard lib do Ruby criando um pequeno(e incompleto) conceito de "Model" de ORM utilizando as classes [PStore](https://ruby-doc.org/stdlib-2.4.0/libdoc/pstore/rdoc/PStore.html)(desenvolvida pelo Matz) e [YAML::Store](https://ruby-doc.org/stdlib-2.4.0/libdoc/yaml/rdoc/YAML/Store.html)  que implementam mecanismos de persistência em disco baseado em `Hash`, sendo possível "serializar" e salvar objetos Ruby. 
Essa parte do código pode ser **desconsiderada** se houver a necessidade, pois a minha intenção também não era criar algo extremamente robusto, somente o básico.

---

### Como rodar?

Primeiramente, você deve clonar o repositório:

`$ git clone https://gitlab.com/fidelisrafael/bank-cli.git`

Mover-se para dentro da pasta, e instalar as dependências (`pry`, `rspec` e  `simplecov`):

**OBS**: Esse projeto utiliza o `ruby-2.4.0` (veja arquivo `Gemfile`). 

```
$ cd bank-cli
$ bundle install
```

Após instalar as dependências, crie alguns `Customer` e `Account` para poder utilizar a CLI com dados validos:

```
$ bin/console

[1](main)> origin_user = Bank::API::Commands.create_customer!(email: 'source@Bank.com', name: 'Source User')

[2](main)> dest_user = Bank::API::Commands.create_customer!(email: 'dest@Bank.com', name: 'Dest User')

# Adicione algum dinheiro na conta do usuário de origem
[3](main)> origin_user.account.update {|account| account.update_amount(5000) }

[4](main)> origin_user.account.amount
=> 5000.0

[5](main)> exit
```

Pronto! Se você quiser verificar o status do banco de dados, simplesmente abra o arquivo `data/db_development.yml` e verifique as informações. Ex:

```yml
---
customers:
- !ruby/object:Bank::Models::Customer
  email: source@Bank.com
  name: Source User
  id: '1924'
- !ruby/object:Bank::Models::Customer
  email: dest@Bank.com
  name: Dest User
  id: 7ffb
accounts:
- !ruby/object:Bank::Models::Account
  customer_id: '1924'
  amount: 5000.0
  id: 52d3
- !ruby/object:Bank::Models::Account
  customer_id: 7ffb
  amount: 0
  id: 34cf
```

Agora, você pode utilizar a CLI para efetuar transações, para visualizar o formato das opções, rode:

```
➜ bin/bank --help
Usage: bin/bank [command] [options]

        --cNAME, --command=COMMAND   Name of the command to run
        --oACCOUNT_ID, --origin=ACCOUNT_ID
                                     The source account ID
        --dACCOUNT_ID, --dest=ACCOUNT_ID
                                     The destination account ID
        --aAMOUNT, --amount=AMOUNT   The total amount of money to be handled
```

#### Comando: Verificar saldo

Para verificar o saldo de uma conta, você pode usar a CLI como:

```
$ bin/bank -c check_balance -o 52d3
Yeah, your transaction is done!

Operation: Balance checking.
Status: Transaction completed successfully

Date: 20/07/2018 15:56:57
Source's account: '52d3' (source@Bank.com)
Amount: R$ 50.0
Execution time: 0.00 ms

Bank 2018
```

Se você tentar verificar o saldo de uma conta que não existe, irá receber um erro (o sistema simplesmente diz que não é valido):

```
➜ bin/bank -c check_balance -o 52d1

[ERROR] The source account ID is not valid
```

#### Comando: Transferir dinheiro

Para transferir dinheiro entre contas, você pode usar a CLI conforme o seguinte exemplo:

> bin/bank -c transfer -d [conta de destino] -o [conta de origem] -a [valor em centavos]

```
# Exemplo de transferencia de R$ 1.00 (100 centavos)
➜ bin/bank -c transfer -d 34cf -o 52d3 -a 100
Yeah, your transaction is done!

Operation: Money transfer between accounts.
Status: Transaction completed successfully

Date: 20/07/2018 15:59:46
Source's account: '52d3' (source@Bank.com)
Destination's account: '34cf' (dest@Bank.com)
Amount: R$ 1.0
Transaction Identifier: 49cbe9ef46840eb46f06027564593a17
Execution time: 0.00 ms

Bank 2018
```
Lembre-se que é impossível transferir **quantias negativas** e/ou **uma quantia maior do que a usuário possui em conta**. Ex:

```
➜ $ bin/bank -c transfer -d 34cf -o 52d3 -a -10

[ERROR] The amount "-10.0" is not valid for this command

# -----
➜ $ bin/bank -c transfer -d 34cf -o 52d3 -a 10000000

[ERROR] There's no enough money in account for this transaction
```

#### Confirmação antes das transferências:

Você pode setar a variavel de ambiente `ENV['CONFIRM']` para tornar obrigatório a **confirmação** da transação antes de executar-la, por exemplo:

```
➜ CONFIRM=true bin/bank -c transfer -d 34cf -o 52d3 -a 1000   
Please, review your transaction.

Operation: Transfer beetwen two accounts.

Date: 20/07/2018 16:28:48
Source's account: '52d3'
Destination's account: '34cf'
Amount: R$ 10.0

Do you want to execute this transaction? If "yes" just type: "yes", otherwise type "no"

=>> no

[ABORTED] This transaction was canceled by the user
```

#### Modo de Debug:

Algumas vezes as mensagens de erro retornadas pelo `CLI` podem ser muitos básicas, porém em desenvolvimento você pode ter a necessidade de obter todo o backtrace de uma exception, para isso execute a aplicação com a variação de ambiente `ENV['DEBUG'] = 'true'`, ex:

```
➜ DEBUG=true bin/bank -c transfer -d 34cf -o 52d31 -a 1000
➜ DEBUG=true bin/bank -c transfer -d 34cf -o 52d31 -a 1000
Running: `transfer` with options: {
  "command_name": "transfer",
  "destination_account_id": "34cf",
  "origin_account_id": "52d31",
  "amount": 1000.0
}

[ERROR] The source account ID is not valid
/diretorio/bank/lib/bank/api/validator.rb:61:in `validate_account!': The source account ID is not valid (Bank::API::InvalidAccountNumberError)
        from /diretorio/bank/lib/bank/api/validator.rb:56:in `validate_source_account!'

```

---

### Decisões de arquitetura

Conforme já introduzido, eu decidi separar cada concern em seu proprio namespace(["Namespaces are one honking great idea -- let's do more of those!"](https://www.python.org/dev/peps/pep-0020/)).
Os namespaces da aplicação são:

- `Bank::API` - Contem regras de negócios e validações **finais** 

- `Bank::CLI` - Implementação de UI no console sobre `Bank::API`

- `Bank::DataStore` - Implementação de repositorio de dados e "banco de dados".

- `Bank::Models`  - Namespace aonde residem os objetos que mapeiam(abstraem) os dados do banco de dados, basicamente PORO (Pure Old Ruby Objects).

Todos os comandos(como `transfer`, `check_balance`) possuem uma classe especifica dentro do namespace: `Bank::API::Commands`. Todos os comandos devem possuir a mesma interface, que basicamente é:

```
require_relative 'base_command'

module Bank
  module API
    class Commands::MyCommand < Commands::BaseCommand
      # just overwrite `initialize` if you need to initialize with some custom data
      # Optional
      def initialize(custom_data)
        super()
      end

      # Required
      def command_name
        'my_command'
      end

      # Required
      def validate!
        raise "Invalid data" if true
      end

      private

      def execute_command!
        # anything that needs to be done here (update database, send email, etc)

        true # or false to notify if the command was executed successfully
      end
    end
  end
end
```

Um comando tem uma API simples de um PORO, você pode verificar algumas informações de cada comando, por exemplo:

```
[1](main)> command = Bank::API::Commands::Transfer.new(origin_account: origin_user.account, destination_account: dest_user.account, amount: 10)
[2](main)> command.execute!

[3](main)> command.success?
=> true
[4](main)> command.error?
=> false
[5](main)> command.executed?
=> true
[6](main)> command.command_name
[=> "transfer"
```

Acho que ainda é possivel melhorar essa "API", porém para essa necessidade creio que está OK.

---

### Testes

Escrevi testes para os pontos mais importantes, ainda faltam escrever testes para os `Models`, pois decidi focar principalmente nos fluxos.

Para rodar os testes, execute:

```
➜ rspec
Running with Simplecov...
SimpleCov.started!
.........................................................................................................

Finished in 0.73323 seconds (files took 0.3186 seconds to load)
105 examples, 0 failures

Coverage report generated for RSpec to /directory/coverage. 1089 / 1140 LOC (95.53%) covered.
```

Você pode verificar o relatório de coverage do `SimpleCov` abrindo o arquivo `coverage/index.html` .

---

### Roadmap

- Write simple tests to Models
- Create WebAPI based on `Bank::API`
- Add interactive mode in CLI
- Remove duplicated code from tests
- Allow multi language support (translation of CLI messages) 
- Allow multiples currencies

---

### FAQ

**P**: `bin/console` não funciona, comofaz?  
**R**: Certifique-se que o arquivo é executável (`chmod +x bin/console` pode tornar-lo executável se ainda não for)


**P**: `bin/bank` não funciona, comofaz?  
**R**: Certifique-se que o arquivo é executável (`chmod +x bin/bank` pode tornar-lo executável se ainda não for)

---

### Contributing

Bug reports and pull requests are welcome on GitLab at https://gitlab.com/fidelisrafael/bank-cli. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the Contributor Covenant code of conduct.

---

### License

The project is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
