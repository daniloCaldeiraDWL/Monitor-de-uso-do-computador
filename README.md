================================================================
  Monitor de Uso  --  Documentação
================================================================

COMO INSTALAR
-------------
1. Extraia a pasta em qualquer local (ex: C:\Monitor de Uso)
2. Duplo clique em  Instalar.bat
3. Aceite o UAC
4. Pronto — roda em segundo plano a partir dai

COMO DESINSTALAR
----------------
Duplo clique em  Desinstalar.bat
Os arquivos de relatorio sao mantidos.

GERAR RELATORIO
---------------
Duplo clique em  GerarRelatorio.bat
Nao precisa de administrador.

ARQUIVOS
--------
Monitor de Uso\
  Instalar.bat              <- instala (precisa de admin 1x)
  Desinstalar.bat           <- remove as tarefas
  GerarRelatorio.bat        <- exibe e salva resumo
  config.ini                <- nome e pasta do relatorio
  scripts\
    RegistrarEvento.ps1     <- script principal (roda em bg)
    GerarRelatorio.ps1      <- logica do relatorio
    executor.vbs            <- lanca PS1 sem abrir nenhuma janela
  relatorios\
    registro.log            <- dados brutos (append, nunca trava)
    registro_resumo.txt     <- resumo gerado pelo relatorio
  queda_energia.log         <- criado so se houver queda de energia

FORMATO DO LOG
--------------
Arquivo texto puro (.log), uma linha por evento.
Pode ficar aberto em qualquer editor sem impedir novos registros.

  dd/MM/yyyy HH:mm:ss | TIPO | Motivo

Exemplo de dia normal:
  08/06/2026 08:04:11 | ATIVACAO   | Desbloqueio
  08/06/2026 12:01:33 | INATIVACAO | Bloqueio
  08/06/2026 13:14:55 | ATIVACAO   | Desbloqueio
  08/06/2026 18:02:07 | INATIVACAO | Bloqueio

DETECCAO DE QUEDA DE ENERGIA
------------------------------
Se o PC desligar sem registrar INATIVACAO (queda de luz,
botao de forca, travamento), na proxima ATIVACAO o sistema:

  1. Insere uma linha INATIVACAO retroativa com motivo
     "Queda de Energia (inferida)"
  2. Registra o ocorrido em queda_energia.log na raiz

O par ATIVACAO / INATIVACAO permanece sempre consistente.

CONFIGURAR NOME DO ARQUIVO
---------------------------
Edite config.ini:
  NomeArquivo     = meu_registro_2026
  PastaRelatorios = relatorios

TAREFAS AGENDADAS CRIADAS
--------------------------
  Monitor de Uso - Ativacao    -> disparado ao desbloquear
  Monitor de Uso - Inativacao  -> disparado ao bloquear

================================================================
