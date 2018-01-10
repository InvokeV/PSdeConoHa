# PSdeConoHa


## PowerShellでConoHaをどうにかしてみる

ConoHa APIを使ってPowerShellのオリジナルコマンドでサーバー管理

"C:\Users\<UserName>\Documents\WindowsPowerShell\Modules"<br>
 このフォルダ内に"PSdeConoHa"フォルダを作成します。PSdeConoHaフォルダ内に"PSdeConoHa.psm1"モジュールファイルを配置します。この時フォルダ名とファイル名は同じにする必要があります。<br>
モジュール化して保存しておくことで自動的に読み込まれコマンドとして利用することができるようになります。<br><be>

ex.<br>
Get-cVM "vps-2018-01-10" | Start-cVM
