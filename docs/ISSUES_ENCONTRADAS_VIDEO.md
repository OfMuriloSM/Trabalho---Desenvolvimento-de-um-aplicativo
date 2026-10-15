# Pendência observada na gravação de 13/10/2026

Ao final do vídeo de validação, durante mudanças na janela do navegador, ocorreu tela vermelha do Flutter com a asserção `debugNeedsLayout is not true` em `rendering/object.dart`. O vídeo não contém stack trace completo para atribuir a falha a um widget específico.

**Status:** não corrigido nem reproduzido localmente neste pacote.

**Reprodução sugerida:** `flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8080`; trocar entre os perfis de administração, professor e aluno; visitar as seções; diminuir a largura do Edge até menos de 400 px, depois ampliar; verificar console/debug e registrar o primeiro erro com stack. Para isolar problemas de layout, priorizar o primeiro stack trace, não as falhas em cascata.

**Critério de encerramento:** ausência de exceções ao alternar 360px, 768px e 1280px nas telas principais, mais `flutter analyze` e `flutter test` aprovados.
