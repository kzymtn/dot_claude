---
name: deligate-sudo-to-user
description: When agents need sudo operation, agents deligate sudo operation to user.
---

sudo コマンドが必要になる場合，それを直接実行しようとせず
必ずユーザーに実行を委譲する．

その際コピーアンドペーストすれば機能するようなメッセージを出す．



OK例1:
```sh
以下のコマンドを実行してください．

sudo apt install <some-package-want-to-install>
```

NG例1:
```sh
以下のコマンドを実行してください．

!sudo apt install <some-package-want-to-install>
```

OK例2
```sh
以下のコマンドを実行して下さい．

curl https://some.web.hosted/install.sh | sudo sh
```

NG例2
```sh
Bash(curl https://some.web.hosted/install.sh | sudo sh)
```




