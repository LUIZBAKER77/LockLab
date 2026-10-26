# LockLab

Scripts PowerShell para preparar os computadores de um laboratório de informática escolar que usam uma conta compartilhada de aluno.

O `LockLab.ps1` aplica a configuração; o `LockLab_REMOVER.ps1` desfaz tudo.

## O que o LockLab.ps1 configura

- **Navegadores (Chrome e Edge):** força navegação anônima/InPrivate, desativa histórico, login e sincronização via políticas em `HKLM`.
- **Atalhos:** cria atalhos do Chrome e do Edge que já abrem a página inicial definida, coloca na área de trabalho e na barra de tarefas da conta do lab.
- **Área de trabalho travada:** nega à conta do aluno permissão de criar ou apagar itens no Desktop, para os atalhos não sumirem.
- **Limpeza a cada logon:** instala `cleanup.ps1` e uma tarefa agendada (`LabCleanup`) que, a cada logon da conta do lab, recria os atalhos e apaga histórico, cookies e cache dos navegadores.

A URL vai como argumento do atalho porque o Chrome ignora as políticas de página inicial quando o modo anônimo é forçado.

## Uso

Abra o PowerShell **como administrador** em cada máquina:

```powershell
.\LockLab.ps1 -LabUser "DOMINIO\aluno" -HomeUrl "https://portal.suaescola.com.br"
```

Parâmetros:

| Parâmetro | Obrigatório | Descrição |
| --- | --- | --- |
| `-LabUser` | sim | conta compartilhada dos alunos, no formato `DOMINIO\usuario` |
| `-HomeUrl` | sim | página que os atalhos abrem |
| `-ToolsPath` | não | pasta onde ficam atalhos e `cleanup.ps1` (padrão `C:\LabTools`) |

Para reverter:

```powershell
.\LockLab_REMOVER.ps1 -LabUser "DOMINIO\aluno"
```

Ele remove as políticas, a tarefa agendada, os atalhos, a pasta de ferramentas e restaura as permissões do Desktop. Reinicie o computador depois.

## Observações

- As políticas valem para a máquina inteira (`HKLM`), não só para a conta do lab.
- Se a política de execução bloquear o script, rode com `powershell -ExecutionPolicy Bypass -File .\LockLab.ps1 ...`.
- Teste em uma máquina antes de aplicar no laboratório todo.
