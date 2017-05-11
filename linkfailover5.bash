#!/bin/bash
#Verifica se a interface esta DOWN ou UP
#---------------------------------------

#Declara a variavel
eth0down=`/sbin/ifconfig eth0 | awk '/inet addr/{print substr($2,6)}'`
#Verifica se h� ou nao o ip na interface
if [ $? -ne 0 ]; then
        #Comando para subir o ip na interface eth0
        /etc/init.d/networking restart
        sleep 5s
        /etc/init.d/ipsec restart
        sleep 5s
        /etc/init.d/firewall
        logger Colocando ip na interface eth0
else
        logger Eth0 com ip na interface
fi

#Configura a rede 4.2.2.2 para o gateway padr�o eth0
#----------------------------------------------------

redeeth0=`cat /etc/network/interfaces | grep gateway | awk '{print ($2)}'`
rotagoogle=`ip route | grep 4.2.2.2 | grep eth0 | awk '{print $3}'`
if [ "$rotagoogle" = "$redeeth0" ]; then
        logger Bot�o ISH BOX WEB desativado - 3G desativado
elif [ "$rotagoogle" = "200.200.200.200" ]; then
        logger Bot�o ISH BOX WEB ativado - 3G ativado
else
        route add -host 4.2.2.2 gw $redeeth0
fi


#Configura o modem com o drive generico e habilita as portas TTY na pasta /dev para o funcionamento do 3G
#--------------------------------------------------------------------------------------------------------

#Declara a vari�vel
detectamodem=`lsusb | grep 12d1 | awk '{print substr($6,6)}'`

if [ "$detectamodem" = "15cd" ];then
        logger Alterando o Drive para o Gen�rico
        usb_modeswitch -v 12d1 -p 15cd -V 12d1 -P 1506 -M 55534243123456780000000000000a11062000000000000100000000000000
elif [ "$detectamodem" = "14fe" ];then
        logger Alterando o Drive para o Gen�rico
        usb_modeswitch -v 12d1 -p 14fe -V 12d1 -P 1506 -M 55534243123456780000000000000a11062000000000000100000000000000
elif [ "$detectamodem2" = "0154" ];then
        logger Colocando a configura��o modem ZTE para gen�rico
        usb_modeswitch -v 19d2 -p 0154 -V 19d2 -P 0117 -M 5553424312345678000000000000061b000000020000000000000000000000
else
        logger Modem j� configurado como generico
fi

#Comando para uma pausa de 5s
#-----------------------------
sleep 5s

#Deixa o 3G preparado para comunicar
#-----------------------------------

#Declara a vari�vel
habilita3g=`ifconfig | grep ppp0 | awk '{print $1}'`

#Habilita o 3G para comunicar se n�o tiver o PPP0
if [ "$habilita3g" = "ppp0" ]; then
        logger Discagem j� realizada no 3G
else
        logger Iniciando discagem 3G
        #Inicia a discagem com o 3G
        /usr/bin/wvdial &
fi

#Comando para uma pausa de 5s
#-----------------------------
sleep 5s

#Efetua a configura��o das rotas: Firewall Martins, Google, Martins, Monitoramento
#----------------------------------------------------------------------------------

#Declara a variavel
level3=4.2.2.2

#Ping para o 4.2.2.2 na interface eth0
ping -c 10 $level3 -I eth0 > /dev/null 2>&1

#Verifica se h� ou nao retorno do ping
if [ $? -ne 0 ]; then
        redeppp1=`ifconfig ppp0 | grep "inet " | awk '{print ($2)}' | awk '{print substr($1,6)}'`
        rotafirewall3g=`ip route | grep 200.251.129.122 | grep $redeppp1 | awk '{print $3}'`
        if [ "$rotafirewall3g" = "$redeppp1" ]; then
                        logger Rota 3G j� adicionada
        else
                        redeppp2=`ifconfig ppp0 | grep inet | awk '{print ($2)}' | awk '{print substr($1,6)}'`
                        logger Adicionando rotas para o 3G
                        route del 200.251.129.122
                        route del 172.19.0.0
                        route del 189.39.25.90
                        route del 93.93.128.191
                        route del 46.235.227.11
                        route del 46.235.227.226
                        route del 93.93.129.193
                        route del 200.236.31.1
                        route del 192.30.253.113
                        route add -host 200.251.129.122 gw $redeppp2
                        route add -host 4.2.2.2 gw $redeppp2
                        route add -host 189.39.25.90 gw $redeppp2
                        route add -host 172.19.0.0 gw $redeppp2
                        route add -host 93.93.128.191 gw $redeppp2
                        route add -host 46.235.227.11 gw $redeppp2
                        route add -host 46.235.227.226 gw $redeppp2
                        route add -host 93.93.129.193 gw $redeppp2
                        route add -host 200.236.31.1 gw $redeppp2
                        route add -host 192.30.253.113 gw $redeppp2
                        #Alterando o IP da linha Left para o IP da ppp0
                        sed -i "s/left=.*/left=$redeppp2/g" /etc/ipsec.conf
        fi
else
        redeeth1=`cat /etc/network/interfaces | grep gateway | awk '{print ($2)}'`
        redeeth2=`/sbin/ifconfig eth0 | awk '/inet addr/{print substr($2,6)}'`
        redeppp3=`ifconfig ppp0 | grep inet | awk '{print ($2)}' | awk '{print substr($1,6)}'`
        rotafirewalleth0=`ip route | grep 200.251.129.122 | grep $redeeth1 | awk '{print $3}'`
        if [ "$rotafirewalleth0" = "$redeeth1" ]; then
                        logger Rota Eth0 j� adicionada
        else
                        killall -2 wvdial 1>/dev/null 2>/dev/null
                        killall -9 pppd 1>/dev/null 2>/dev/null
                        logger adicionando rotas eth0
                        #Delete as rotas para a interface ppp0
                        route del 200.251.129.122
                        route del 189.39.25.90
                        route del 172.19.0.0
	                route del 93.93.128.191
        	        route del 46.235.227.11
                	route del 46.235.227.226
	                route del 93.93.129.193
        	        route del 200.236.31.1
                	route del 192.30.253.113
                        route del 4.2.2.2 gw $redeppp3
                        #Cria as rotas para a interface eth0
                        route add -host 200.251.129.122 gw $redeeth1
                        route add -host 4.2.2.2 gw $redeeth1
                        route add -host 189.39.25.90 gw $redeeth1
                        route add -host 172.19.0.0 gw $redeeth1
                        route add -host 93.93.128.191 gw $redeeth1
                        route add -host 46.235.227.11 gw $redeeth1
                        route add -host 46.235.227.226 gw $redeeth1
                        route add -host 93.93.129.193 gw $redeeth1
                        route add -host 200.236.31.1 gw $redeeth1
                        route add -host 192.30.253.113 gw $redeeth1
                        logger Colocando o IP da interface eth0 pelo ifconfig no ipsec.conf
                        #Alterando o IP da linha Left para o IP da eth0
                        sed -i "s/left=.*/left=$redeeth2/g" /etc/ipsec.conf
        fi
fi

#Efetua o teste de ping para o servidor da martins, se funcionar o ping ele muda o ipsec para o 3G, sen�o ele funciona pela eth0
#--------------------------------------------------------------------------------------------------------------------------------

#Declara as variaveis
ipvpntest=172.19.2.21

#Comando para testar o ping no ip 172.19.2.21
ping -c 10 $ipvpntest > /dev/null 2>&1

#Verifica se funcionou ou n�o o ping
if [ $? -ne 0 ]; then
        #Efetua o restart no ipsec
        logger restartando ipsec
        /etc/init.d/ipsec restart
        /etc/init.d/ssh restart
else
        logger VPN funcionando
fi