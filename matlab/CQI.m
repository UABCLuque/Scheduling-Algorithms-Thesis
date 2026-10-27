%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CQI
%
% Funcion
% Según Rel.12 y posterior. Tabla 7.2.3-1 en 3GPP TS 36.213 verison 14.2.0
%
% https://lh3.googleusercontent.com/proxy/vp9EM7xTaAA1nGl467UtIUrCGaebEmFKQjkvtaVNBSaoGSJDCbSk7zNk8b3fkv-ZDLYGYTQMn8ESZxgCb1mIhxqTqzSwG0s
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function  bRE = CQI(SNR_UE, ~)

if      (SNR_UE >= -6.7 && SNR_UE < -4.7)
            %disp('Indice de CQI = 1')
            %disp('QPSK, 78/1024')
            CR = 78/1024;                       %Code rate
            bRE = CR*2;                         %Segun la tabla Code rate * bits por simbolo
    elseif (SNR_UE >= -4.7 && SNR_UE < -2.3)
            %disp('Indice de CQI = 2')
            %disp('QPSK, 120/1024')
            CR = 120/1024;
            bRE = CR*2;
    elseif (SNR_UE >= -2.3 && SNR_UE < 0.2)
            %disp('Indice de CQI = 3')
            %disp('QPSK, 193/1024')
            CR = 193/1024;
            bRE = CR*2;
    elseif (SNR_UE >= 0.2 && SNR_UE < 2.4)
            %disp('Indice de CQI = 4')
            %disp('QPSK, 308/1024')
            CR = 308/1024;
            bRE = CR*2;
    elseif (SNR_UE >= 2.4 && SNR_UE < 4.3)
            %disp('Indice de CQI = 5')
            %disp('QPSK, 449/1024')
            CR = 449/1024;
            bRE = CR*2;
    elseif (SNR_UE >= 4.3 && SNR_UE < 5.9)
            %disp('Indice de CQI = 6')
            %disp('QPSK, 602/1024')
            CR = 602/1024;
            bRE = CR*2;
    elseif (SNR_UE >= 5.9 && SNR_UE < 8.1)
            %disp('Indice de CQI = 7')
            %disp('16QAM, 378/1024')
            CR = 378/1024;
            bRE = CR*4;
    elseif (SNR_UE >= 8.1 && SNR_UE < 10.3)
            %disp('Indice de CQI = 8')
            %disp('16QAM, 490/1024')
            CR = 490/1024;
            bRE = CR*4;
    elseif (SNR_UE >= 10.3 && SNR_UE < 11.7)
            %disp('Indice de CQI = 9')
            %disp('16QAM, 616/1024')
            CR = 616/1024;
            bRE = CR*4;
    elseif (SNR_UE >= 11.7 && SNR_UE < 14.1)
            %disp('Indice de CQI = 10')
            %disp('64QAM, 466/1024')
            CR = 466/1024;
            bRE = CR*6;     %64QAM son 6 bits por simbolo
    elseif (SNR_UE >= 14.1 && SNR_UE < 16.3)
            %disp('Indice de CQI = 11')
            %disp('64QAM, 567/1024')
            CR = 567/1024;
            bRE = CR*6;
    elseif (SNR_UE >= 16.3 && SNR_UE < 18.7)
            %disp('Indice de CQI = 12')
            %disp('64QAM, 666/1024')
            CR = 666/1024;
            bRE = CR*6;
    elseif (SNR_UE >= 18.7 && SNR_UE < 21)
            %disp('Indice de CQI = 13')
            %disp('64QAM, 772/1024')
            CR = 772/1024;
            bRE = CR*6;
    elseif (SNR_UE >= 21 && SNR_UE < 22.7)
            %disp('Indice de CQI = 14')
            %disp('64QAM, 873/1024')
            CR = 873/1024;
            bRE = CR*6;
    elseif (SNR_UE >= 22.7)
            %disp('Indice de CQI = 15')
            %disp('64QAM, 948/1024')
            CR = 948/1024;
            bRE = CR*6;
    else
        %disp('Indice de CQI = 0')
        bRE = 0;
end

    % bRE ya es la eficiencia espectral de un RE (bits/RE) segun la tabla de
    % CQI. El BW no escala bRE: entra en el numero de RB por frame.

end

