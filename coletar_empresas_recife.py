"""
Coleta empresas de Recife (PE) sem website via Google Maps Places API
e gera PDF + CSV com os resultados.

Pré-requisitos:
    pip install googlemaps pandas reportlab requests

Como obter a chave da API (GRATUITO até $200/mês):
    1. Acesse https://console.cloud.google.com/
    2. Crie um projeto
    3. Ative: "Places API" e "Maps JavaScript API"
    4. Vá em "Credenciais" > "Criar credencial" > "Chave de API"
    5. Cole a chave na variável API_KEY abaixo
"""

import time
import csv
import requests
import json
from datetime import datetime

# ─────────────────────────────────────────────
#  CONFIGURAÇÃO — preencha sua chave aqui
# ─────────────────────────────────────────────
API_KEY = "SUA_CHAVE_GOOGLE_MAPS_AQUI"

# Categorias de negócios a pesquisar em Recife
CATEGORIAS = [
    "barbearia",
    "salão de beleza",
    "borracharia",
    "oficina mecânica",
    "padaria",
    "mercadinho",
    "açougue",
    "lanchonete",
    "serralheria",
    "funilaria",
    "chaveiro",
    "encanador",
    "eletricista",
    "marcenaria",
    "lavanderia",
    "costureira alfaiataria",
    "dedetizadora",
    "gráfica",
    "pet shop",
    "farmácia de manipulação",
]

# Localização central de Recife (latitude, longitude)
RECIFE_LAT = -8.0476
RECIFE_LNG = -34.8770
RAIO_METROS = 15000  # 15 km cobre Recife inteiro

META_EMPRESAS = 100  # quantas empresas sem site queremos encontrar

# ─────────────────────────────────────────────
#  FUNÇÕES PRINCIPAIS
# ─────────────────────────────────────────────

def buscar_places(categoria: str, next_page_token: str = None) -> dict:
    """Chama a Nearby Search API do Google Maps."""
    url = "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
    params = {
        "location": f"{RECIFE_LAT},{RECIFE_LNG}",
        "radius": RAIO_METROS,
        "keyword": categoria,
        "language": "pt-BR",
        "key": API_KEY,
    }
    if next_page_token:
        params = {"pagetoken": next_page_token, "key": API_KEY}

    resp = requests.get(url, params=params, timeout=10)
    resp.raise_for_status()
    return resp.json()


def buscar_detalhes(place_id: str) -> dict:
    """Busca detalhes completos de um lugar: telefone, website, endereço."""
    url = "https://maps.googleapis.com/maps/api/place/details/json"
    params = {
        "place_id": place_id,
        "fields": "name,formatted_address,formatted_phone_number,international_phone_number,website,business_status,opening_hours,types",
        "language": "pt-BR",
        "key": API_KEY,
    }
    resp = requests.get(url, params=params, timeout=10)
    resp.raise_for_status()
    return resp.json().get("result", {})


def formatar_whatsapp(telefone: str) -> str:
    """Converte número para link de WhatsApp removendo caracteres especiais."""
    if not telefone:
        return ""
    numeros = "".join(c for c in telefone if c.isdigit())
    # Remove o 0 do DDD se vier com 0 na frente
    if numeros.startswith("0"):
        numeros = numeros[1:]
    # Garante código Brasil
    if not numeros.startswith("55"):
        numeros = "55" + numeros
    return f"https://wa.me/{numeros}"


def coletar_empresas() -> list[dict]:
    """Percorre categorias e coleta empresas sem website até atingir a meta."""
    empresas_sem_site = []
    place_ids_vistos = set()

    print(f"\n{'='*60}")
    print(f"  COLETANDO EMPRESAS DE RECIFE SEM WEBSITE")
    print(f"  Meta: {META_EMPRESAS} empresas")
    print(f"{'='*60}\n")

    for categoria in CATEGORIAS:
        if len(empresas_sem_site) >= META_EMPRESAS:
            break

        print(f"[→] Buscando: {categoria.upper()}")
        next_token = None
        paginas = 0

        while paginas < 3:  # Google retorna no máximo 3 páginas (60 resultados)
            if len(empresas_sem_site) >= META_EMPRESAS:
                break

            try:
                if next_token:
                    time.sleep(2)  # obrigatório antes de usar next_page_token
                dados = buscar_places(categoria, next_token)
            except requests.RequestException as e:
                print(f"    [ERRO] Falha na busca: {e}")
                break

            resultados = dados.get("results", [])
            if not resultados:
                break

            for lugar in resultados:
                if len(empresas_sem_site) >= META_EMPRESAS:
                    break

                place_id = lugar.get("place_id")
                if not place_id or place_id in place_ids_vistos:
                    continue
                place_ids_vistos.add(place_id)

                # Status do negócio
                if lugar.get("business_status") == "CLOSED_PERMANENTLY":
                    continue

                try:
                    time.sleep(0.1)  # evita rate limit
                    detalhes = buscar_detalhes(place_id)
                except requests.RequestException as e:
                    print(f"    [ERRO] Detalhes falhou: {e}")
                    continue

                website = detalhes.get("website", "")
                telefone = detalhes.get("formatted_phone_number", "")
                telefone_intl = detalhes.get("international_phone_number", "")

                # Filtro principal: sem website E com telefone
                if website:
                    continue
                if not telefone:
                    continue

                nome = detalhes.get("name", lugar.get("name", ""))
                endereco = detalhes.get("formatted_address", "")
                status = lugar.get("business_status", "OPERATIONAL")

                empresa = {
                    "N°": len(empresas_sem_site) + 1,
                    "Nome": nome,
                    "Categoria": categoria.title(),
                    "Telefone": telefone,
                    "WhatsApp": formatar_whatsapp(telefone_intl or telefone),
                    "Endereço": endereco,
                    "Website": "Não possui",
                    "Status": "Ativo" if status == "OPERATIONAL" else status,
                }

                empresas_sem_site.append(empresa)
                print(f"    [✓] {len(empresas_sem_site):>3}. {nome} — {telefone}")

            next_token = dados.get("next_page_token")
            if not next_token:
                break
            paginas += 1

    print(f"\n[✓] Total coletado: {len(empresas_sem_site)} empresas sem website\n")
    return empresas_sem_site


# ─────────────────────────────────────────────
#  EXPORTAÇÃO CSV
# ─────────────────────────────────────────────

def exportar_csv(empresas: list[dict], arquivo: str):
    if not empresas:
        return
    campos = list(empresas[0].keys())
    with open(arquivo, "w", newline="", encoding="utf-8-sig") as f:
        writer = csv.DictWriter(f, fieldnames=campos)
        writer.writeheader()
        writer.writerows(empresas)
    print(f"[✓] CSV salvo: {arquivo}")


# ─────────────────────────────────────────────
#  EXPORTAÇÃO PDF
# ─────────────────────────────────────────────

def exportar_pdf(empresas: list[dict], arquivo: str):
    try:
        from reportlab.lib.pagesizes import A4
        from reportlab.lib import colors
        from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
        from reportlab.lib.units import cm
        from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer
        from reportlab.lib.enums import TA_CENTER
    except ImportError:
        print("[!] ReportLab não instalado. Rodando: pip install reportlab")
        import subprocess, sys
        subprocess.check_call([sys.executable, "-m", "pip", "install", "reportlab", "-q"])
        from reportlab.lib.pagesizes import A4
        from reportlab.lib import colors
        from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
        from reportlab.lib.units import cm
        from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer
        from reportlab.lib.enums import TA_CENTER

    doc = SimpleDocTemplate(
        arquivo,
        pagesize=A4,
        leftMargin=1.5 * cm,
        rightMargin=1.5 * cm,
        topMargin=2 * cm,
        bottomMargin=2 * cm,
    )

    styles = getSampleStyleSheet()
    titulo_style = ParagraphStyle(
        "titulo",
        parent=styles["Title"],
        fontSize=16,
        textColor=colors.HexColor("#1a1a2e"),
        spaceAfter=6,
        alignment=TA_CENTER,
    )
    sub_style = ParagraphStyle(
        "sub",
        parent=styles["Normal"],
        fontSize=9,
        textColor=colors.grey,
        alignment=TA_CENTER,
        spaceAfter=16,
    )
    celula_style = ParagraphStyle(
        "celula",
        parent=styles["Normal"],
        fontSize=7.5,
        leading=10,
    )

    elementos = []

    # Cabeçalho
    elementos.append(Paragraph("Empresas de Recife (PE) sem Website", titulo_style))
    elementos.append(Paragraph(
        f"Gerado em {datetime.now().strftime('%d/%m/%Y %H:%M')} — Total: {len(empresas)} empresas",
        sub_style,
    ))

    # Cabeçalho da tabela
    cabecalho = ["N°", "Nome", "Categoria", "Telefone", "WhatsApp (link)", "Endereço", "Status"]
    dados_tabela = [cabecalho]

    for e in empresas:
        linha = [
            str(e["N°"]),
            Paragraph(e["Nome"], celula_style),
            Paragraph(e["Categoria"], celula_style),
            Paragraph(e["Telefone"], celula_style),
            Paragraph(e["WhatsApp"], celula_style),
            Paragraph(e["Endereço"], celula_style),
            e["Status"],
        ]
        dados_tabela.append(linha)

    # Larguras das colunas (total ~18cm)
    col_widths = [1 * cm, 3.5 * cm, 2.5 * cm, 2.5 * cm, 3.5 * cm, 4.5 * cm, 1.5 * cm]

    tabela = Table(dados_tabela, colWidths=col_widths, repeatRows=1)
    tabela.setStyle(TableStyle([
        # Cabeçalho
        ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#1a1a2e")),
        ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
        ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
        ("FONTSIZE", (0, 0), (-1, 0), 8),
        ("ALIGN", (0, 0), (-1, 0), "CENTER"),
        ("VALIGN", (0, 0), (-1, 0), "MIDDLE"),
        ("BOTTOMPADDING", (0, 0), (-1, 0), 8),
        ("TOPPADDING", (0, 0), (-1, 0), 8),
        # Corpo
        ("FONTNAME", (0, 1), (-1, -1), "Helvetica"),
        ("FONTSIZE", (0, 1), (-1, -1), 7.5),
        ("VALIGN", (0, 1), (-1, -1), "TOP"),
        ("TOPPADDING", (0, 1), (-1, -1), 5),
        ("BOTTOMPADDING", (0, 1), (-1, -1), 5),
        ("LEFTPADDING", (0, 0), (-1, -1), 4),
        ("RIGHTPADDING", (0, 0), (-1, -1), 4),
        # Grid
        ("GRID", (0, 0), (-1, -1), 0.4, colors.HexColor("#cccccc")),
        # Linhas alternadas
        ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, colors.HexColor("#f5f5f5")]),
        # Coluna N° centralizada
        ("ALIGN", (0, 1), (0, -1), "CENTER"),
        ("ALIGN", (-1, 1), (-1, -1), "CENTER"),
    ]))

    elementos.append(tabela)
    elementos.append(Spacer(1, 0.5 * cm))
    elementos.append(Paragraph(
        "Dados coletados via Google Maps Places API. Verifique disponibilidade antes de contatar.",
        ParagraphStyle("rodape", parent=styles["Normal"], fontSize=7, textColor=colors.grey, alignment=TA_CENTER),
    ))

    doc.build(elementos)
    print(f"[✓] PDF salvo: {arquivo}")


# ─────────────────────────────────────────────
#  SCRIPT DE ABORDAGEM (BÔNUS)
# ─────────────────────────────────────────────

SCRIPT_ABORDAGEM = """
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  MELHOR ABORDAGEM PARA CONTATO — TEMPLATE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📱 MENSAGEM WHATSAPP (1ª abordagem — não venda nada):
──────────────────────────────────────────────
Olá! Tudo bem? Me chamo [SEU NOME].
Vi que o [NOME DA EMPRESA] ainda não tem um site.
Já perdi clientes por isso — hoje em dia,
quem não aparece no Google não existe.
Posso te mostrar em 5 minutos como resolver isso?
Não custa nada dar uma olhada 😊
──────────────────────────────────────────────

📞 LIGAÇÃO (se não responder WhatsApp em 24h):
──────────────────────────────────────────────
"Boa tarde! É d[o/a] [NOME DA EMPRESA]?
Ótimo. Tô ligando porque pesquisei serviços
de [CATEGORIA] aqui no Recife e vi que vocês
não aparecem no Google quando alguém procura.
Tenho uma solução rápida e barata pra isso.
São 5 minutos — pode me ouvir agora?"
──────────────────────────────────────────────

⚡ DICAS DE CONVERSÃO:
• Não mencione "site" ou "preço" na 1ª mensagem
• Primeiro gere curiosidade, depois apresente
• Horário ideal: seg-sex 9h-11h ou 14h-16h
• Taxa de resposta WhatsApp: ~40-60%
• A cada 10 contatos espere 3-4 respostas
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
"""


# ─────────────────────────────────────────────
#  MAIN
# ─────────────────────────────────────────────

def main():
    if API_KEY == "SUA_CHAVE_GOOGLE_MAPS_AQUI":
        print("\n" + "="*60)
        print("  ATENÇÃO: configure sua chave de API primeiro!")
        print("  Edite a variável API_KEY no topo deste arquivo.")
        print("\n  Como obter a chave GRATUITA:")
        print("  1. console.cloud.google.com")
        print("  2. Crie um projeto")
        print("  3. Ative 'Places API'")
        print("  4. Credenciais > Criar chave de API")
        print("="*60 + "\n")
        return

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    arquivo_csv = f"empresas_recife_sem_site_{timestamp}.csv"
    arquivo_pdf = f"empresas_recife_sem_site_{timestamp}.pdf"

    # Coleta
    empresas = coletar_empresas()

    if not empresas:
        print("[!] Nenhuma empresa encontrada. Verifique sua chave de API.")
        return

    # Exporta
    exportar_csv(empresas, arquivo_csv)
    exportar_pdf(empresas, arquivo_pdf)

    # Exibe script de abordagem
    print(SCRIPT_ABORDAGEM)

    print(f"\n[✓] PRONTO!")
    print(f"    Empresas coletadas : {len(empresas)}")
    print(f"    CSV                : {arquivo_csv}")
    print(f"    PDF                : {arquivo_pdf}\n")


if __name__ == "__main__":
    main()
