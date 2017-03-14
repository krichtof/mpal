module ApplicationHelper
  APP_NAME = "Les aides de l’Anah"
  COMPANY_NAME = "Anah"
  SITE_START_YEAR = 2017

  def app_name
    APP_NAME
  end

  # Samples:
  #   = btn name: 'A button'
  #   = btn name: 'A link', href: '#'
  #   = btn name: 'A button with stuff', class: 'btn-large', icon: 'ok'
  #
  # Arguments should be an hash:
  # * name: mandatory, text to render
  # * tag: optional, default to `button`, `a` if `href` is present
  # * href: optional, URL to link to, if present change default `tag` to `a`
  # * class: optional, CSS classes to append
  # * icon: optional, glyphicon to use (without prefix), cf http://getbootstrap.com/components/#glyphicons-glyphs
  def btn(opts = {})
    p = {}
    p[:class] = ['btn']
    p[:class] += opts[:class].split if opts[:class].present?
    p[:class] << 'btn-icon' if opts[:icon].present?
    p[:class] = p[:class].flatten
    p[:href] = opts[:href] if opts[:href].present?
    opts[:tag] ||= :a if opts[:href].present?
    capture do
      content_tag (opts[:tag] || :button), p do
        if opts[:icon].present?
          content_tag(:i, '', class: "glyphicon glyphicon-#{opts[:icon]}") + opts[:name]
        else
          opts[:name]
        end
      end
    end
  end

  def company_name
    COMPANY_NAME
  end

  def copyright_years
    year = Time.now.year
    year > SITE_START_YEAR ? "#{SITE_START_YEAR}&ndash;#{year}".html_safe : year.to_s
  end

  def demandeur?
    @role_utilisateur && @role_utilisateur.to_sym == :demandeur
  end

  def format_date(date, format = :default)
    return '' if date.blank?
    date = date.to_date unless date.is_a?(Date)
    I18n.localize(date, format: format)
  end

  def projet_suffix
    demandeur? ? "demandeur" : "intervenant"
  end

  def readable_bool(boolean)
    boolean ? "Oui" : "Non"
  end

  def with_semicolon(string)
    string + " : "
  end

  def transmission_instructeur(projet)
    if @role_utilisateur  == :intervenant
      form_tag(projet_transmissions_path(projet_id: projet.id), method: 'post', class:'ui form' ) do
        submit_tag t('projets.proposition.action', instructeur: Intervenant.instructeur_pour(projet).to_s), class:'ui primary button'
      end
    end
  end

  def display_errors resource, message_header
    return '' if (resource.errors.empty?)
    messages = resource.errors.messages.map { |key, msg|
      msg.map { |message| content_tag(:li, message) }.join
    }.join
    html = <<-HTML
    <div class="ui icon negative message">
      <i class="warning sign icon"></i>
      <div class="content">
        <div class="header">#{message_header}</div>
        <ul class="list">#{messages}</ul>
      </div>
    </div>
    HTML
    html.html_safe
  end

  def affiche_erreurs_avec_cle resource, message_header
    return '' if (resource.errors.empty?)
    messages = resource.errors.messages.map { |key, msg|
      msg.map { |message| content_tag(:li, "#{key} #{message}") }.join
    }.join
    html = <<-HTML
    <div class="ui icon negative message">
      <i class="warning sign icon"></i>
      <div class="content">
        <div class="header">#{message_header}</div>
        <ul class="list">
    #{messages}
        </ul>
      </div>
    </div>
    HTML
    html.html_safe
  end

  def icone_evenement(label)
    liste_icone = {choix_intervenant: 'pin', transmis_instructeur: 'external', creation_projet: 'suitcase', invitation_intervenant: 'plug', mise_en_relation_intervenant: 'plug', ajout_avis_imposition: "file text outline" }
    liste_icone[label.to_sym]
  end

  def bouton_retour_projet_courant
    link_to 'Retour au projet', @projet_courant, class: "ui button"
  end

  def prestation_checkbox(projet, prestation)
    checked = projet.prestations.include?(prestation)
    check_box_tag 'projet[prestation_ids][]', prestation.id, checked, id: "prestation_#{prestation.id}"
  end

  def bouton_ajout_occupant
    if demandeur?
      html = <<-HTML
      <div class="ui small button">
        <i class="add icon"></i>
      #{link_to t('projets.visualisation.lien_ajout_occupant'), new_projet_occupant_path(@projet_courant) if demandeur?}
      </div>
      HTML
      html.html_safe
    end
  end

  def bouton_suppression_occupant(occupant)
    if demandeur?
      html = <<-HTML
        <i class="trash icon"></i>
      #{link_to 'Supprimer', projet_occupant_path(@projet_courant, occupant), method: :delete}
      </div>
      HTML
      html.html_safe
    end
  end

  def bouton_modification_occupant(occupant)
    if demandeur?
      html = <<-HTML
        <i class="write square icon"></i>
      #{link_to 'Modifier', edit_projet_occupant_path(@projet_courant, occupant)}
      </div>
      HTML
      html.html_safe
    end
  end

  def bouton_modifier_composition
    if demandeur?
      html = <<-HTML
      <div class="ui right floated icon button">
        <i class="user icon"></i>
      #{link_to t('projets.visualisation.modifier_liste_occupant'), edit_projet_composition_path(@projet_courant)}
      </div>
      HTML
      html.html_safe
    end
  end

  def bouton_suppression_document(document)
    link_to projet_document_path(@projet_courant, document), method: :delete do
      content_tag(:i, "", class: "trash icon")
    end
  end

  def annee_fiscale_reference
    @projet_courant.annee_fiscale_reference
  end

  def revenu_fiscal_reference_total
    @projet_courant.revenu_fiscal_reference_total
  end

  def calcul_preeligibilite(annee)
    plafond = @projet_courant.preeligibilite(annee)
    affiche_message_eligibilite(plafond)
  end

  def affiche_message_eligibilite(revenus)
    t("projets.composition_logement.calcul_preeligibilite.#{revenus}")
  end

  def bouton_modification_projet(projet)
    link_to t('projets.visualisation.lien_edition'), edit_projet_path(projet)
  end

  def icone_presence(projet, attribut)
    liste_message = {
      adresse: 'Adresse : ',
      annee_construction: 'Année de construction : ',
      email: 'Email : ',
      tel: 'Téléphone : '
    }
    projet.send(attribut).present? ? content_tag(:i, "", class: "checkmark box icon") + liste_message[attribut] : content_tag(:i, "", class: "square outline icon") + "#{liste_message[attribut] } Veuillez renseigner cette donnée"
  end

  def icone_nombre_occupant(projet)
    projet.nb_total_occupants.present? ? content_tag(:i, "", class: "checkmark box icon") : content_tag(:i, "", class: "square outline icon") + "Nombre d'occupants ?"
  end

  def icone_revenus(projet, annee)
    calcul_revenu_fiscal_reference_total(annee) ? content_tag(:i, "", class: "checkmark box icon") + "Revenus #{annee} : " : content_tag(:i, "", class: "square outline icon") + "Revenus manquants"
  end

  def affiche_intervenants(projet)
    if projet.prospect?
      projet.intervenants.map(&:raison_sociale).join(', ')
    else
      projet.operateur.raison_sociale if projet.operateur
    end
  end

  def menu_actif?(url)
    active = current_page?(url) ? "active item" : "item"
  end

  def affiche_demande_souhaitee(demande)
    html = content_tag(:h4, "Adresse du logement")
    html << content_tag(:p, demande.projet.adresse.description)
    html << content_tag(:h4, "Difficultés rencontrées dans le logement")
    besoins = []
    besoins << t("demarrage_projet.etape2_description_projet.changement_chauffage") if demande.changement_chauffage
    besoins << t("demarrage_projet.etape2_description_projet.froid") if demande.froid
    besoins << t("demarrage_projet.etape2_description_projet.probleme_deplacement") if demande.probleme_deplacement
    besoins << t("demarrage_projet.etape2_description_projet.accessibilite") if demande.accessibilite
    besoins << t("demarrage_projet.etape2_description_projet.hospitalisation") if demande.hospitalisation
    besoins << t("demarrage_projet.etape2_description_projet.adaptation_salle_de_bain") if demande.adaptation_salle_de_bain
    besoins << "#{t("demarrage_projet.etape2_description_projet.autre")} : #{demande.autre}" if demande.autre.present?
    html << content_tag(:ul) do
      besoins.map { |besoin| content_tag(:li, besoin.html_safe) }.join.html_safe
    end
    html << content_tag(:h4, "Travaux envisagés")
    travaux = []
    travaux << t("demarrage_projet.etape2_description_projet.travaux_fenetres") if demande.travaux_fenetres
    travaux << t("demarrage_projet.etape2_description_projet.travaux_isolation") if demande.travaux_isolation
    travaux << t("demarrage_projet.etape2_description_projet.travaux_chauffage") if demande.travaux_chauffage
    travaux << t("demarrage_projet.etape2_description_projet.travaux_adaptation_sdb") if demande.travaux_adaptation_sdb
    travaux << t("demarrage_projet.etape2_description_projet.travaux_monte_escalier") if demande.travaux_monte_escalier
    travaux << t("demarrage_projet.etape2_description_projet.travaux_amenagement_ext") if demande.travaux_amenagement_ext
    travaux << "#{t("demarrage_projet.etape2_description_projet.travaux_autres")} : #{demande.travaux_autres}" if demande.travaux_autres.present?
    html << content_tag(:ul) do
      travaux.map { |tache| content_tag(:li, tache.html_safe) }.join.html_safe
    end
    html << content_tag(:h4, "Informations supplémentaires")
    complements = []
    complements << "Je préfère être contacté " + demande.projet.disponibilite if demande.projet.disponibilite.present?
    ptz = demande.ptz ? "Oui": "Non"
    ptz_strong = content_tag(:strong, ptz)
    complements << "#{t("demarrage_projet.etape2_description_projet.ptz")} : #{ptz_strong}"
    annee_construction = demande.annee_construction.present? ? demande.annee_construction : "Non renseigné"
    annee_construction_strong = content_tag(:strong, annee_construction)
    complements << "#{t("demarrage_projet.etape2_description_projet.annee_construction")} : #{annee_construction_strong}"
    if demande.complement.present?
      complements << "#{t("demarrage_projet.etape2_description_projet.precisions")} : #{content_tag(:strong, demande.complement)}"
    end
    html << content_tag(:ul) do
      complements.map { |complement| content_tag(:li, complement.html_safe) }.join.html_safe
    end
  end

  def i18n_simple_form_label(model, key)
    translation = I18n.t("simple_form.labels.#{model}.#{key}", default: "")
    translation = I18n.t("simple_form.labels.defaults.#{key}", default: "") if translation.blank?
    translation = I18n.t("models.attributes.#{model}.#{key}", default: key.to_s.humanize) if translation.blank?
    translation
  end

  def dossier_opal_url(numero)
    "#{ENV['OPAL_API_BASE_URI']}sio/ctrl/accueil?FORM_DTO_ID=DTO_RECHERCHE_RAPIDE_DOSSIER_CRITERE&FORM_ACTION=RECHERCHER_RAPIDE_DOSSIER&$DTO_RECHERCHE_RAPIDE_DOSSIER_CRITERE$DOS_NUMERO=#{numero}"
  end

  def status_for_operateur(status)
    return if status.blank?
    status_sym = status.to_sym
    return :en_cours_de_montage if [:en_cours, :proposition_enregistree, :proposition_proposee, :proposition_acceptee].include? status_sym
    return status_sym if [:prospect, :en_cours_d_instruction].include? status_sym
    :depose
  end
end
