<#
.SYNOPSIS
    Diagnóstico avançado de PRT e reparo de conta corporativa.
    
.DESCRIPTION
    Verifica o estado do Web Account Manager (WAM) e abre a URI de Shared Experiences
    para resolução de problemas de credenciais "não verificadas".
#>
[CmdletBinding()]
param()

process {
    try {
        Write-Host "--- DIAGNÓSTICO DE IDENTIDADE GB ---" -ForegroundColor Cyan
        
        # 1. Captura o status detalhado
        $dsreg = dsregcmd /status
        
        $prtStatus = ($dsreg | Select-String "AzureAdPrt : YES")
        $tpmStatus = ($dsreg | Select-String "TpmPresent : YES")
        $wamStatus = ($dsreg | Select-String "WamDefaultSet : YES")

        # Exibição de Status para o usuário
        Write-Host "AzureAdPrt (Token): $(if($prtStatus){'OK'}else{'FALHA'})" -ForegroundColor $(if($prtStatus){'Green'}else{'Red'})
        Write-Host "TPM Presente: $(if($tpmStatus){'OK'}else{'FALHA'})" -ForegroundColor $(if($tpmStatus){'Green'}else{'Red'})
        Write-Host "WAM Default (Broker): $(if($wamStatus){'OK'}else{'FALHA'})" -ForegroundColor $(if($wamStatus){'Green'}else{'Red'})

        # 2. Lógica de Reparo
        if (!$prtStatus -or !$wamStatus) {
            Write-Host "`n[!] Erro de Credenciais Detectado." -ForegroundColor Yellow
            Write-Host "Invocando interface de Reparo de Experiências Compartilhadas..." -ForegroundColor Cyan
            
            # Abre a página de "Experiências Compartilhadas" onde o botão "Corrigir Agora" reside
            Start-Process "ms-settings:sharedexperiences"
            
            Write-Host "`n[AÇÃO NECESSÁRIA]:" -ForegroundColor White -BackgroundColor Red
            Write-Host "Verifique a janela de Configurações que abriu." -ForegroundColor White
            Write-Host "Se houver uma mensagem em vermelho dizendo 'Algumas contas precisam de atenção', clique em 'Corrigir Agora'." -ForegroundColor Yellow
        }
        else {
            Write-Host "`n[OK] A identidade parece íntegra no nível de protocolo." -ForegroundColor Green
            Write-Host "Forçando re-autenticação de contexto via Workplace..." -ForegroundColor Cyan
            
            # Abre a área de Contas de Trabalho para forçar o Refresh visual
            Start-Process "ms-settings:workplace"
        }

    }
    catch {
        Write-Error "Erro ao processar diagnóstico: $($_.Exception.Message)"
    }
}
