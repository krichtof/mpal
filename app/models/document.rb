class Document < ApplicationRecord
  belongs_to :category, polymorphic: true
  mount_uploader :fichier, DocumentUploader

  validates :label, :fichier, presence: true

  def self.for_payment(payment)
    hash = { required: [], none: [:autres_paiement] }

    hash[:required] << (payment.type_paiement.to_sym == :avance ? :devis_paiement : :factures)
    hash[:required] << :rib
    hash[:required] << :mandat_paiement if payment.procuration
    #TODO Quand on aura intégré les mandats
    #hash[:required] << :demande_signee if projet.mandat?
    hash[:required] << :plan_financement if payment.type_paiement.to_sym == :solde

    hash
  end

  def self.for_projet(projet)
    projet_themes = projet.themes.map(&:libelle)

    if ENV["ELIGIBLE_HMA"] == "true" && projet.hma.present?
      hash = { required: [:devis_projet], none: [:signature_PTZ] }
      hash[:none] << :justificatif_changement_situation
      hash[:none] << :autres_projet
    else
      hash = { required: [], one_of: [[:devis_projet, :estimation]], none: [:autres_projet] }
    end
    #TODO Quand on aura intégré les mandats
    #hash[:required] << :mandat_projet if projet.mandat?

    if projet_themes.include?("Autonomie") && projet.hma.nil?
      hash[:required] << :justificatif_autonomie
      hash[:required] << :diagnostic_autonomie
    end

    if projet_themes.include? ("Énergie") && projet.hma.nil?
      hash[:required] << :evaluation_energetique
      hash[:required] << :contrat_amo if projet.invited_pris.present? #projet.operation.present?
    end

    if projet_themes.include? ("SSH - petite LHI") && projet.hma.nil?
      hash[:one_of] << [:arrete_insalubrite_peril, :rapport_grille_insalubrite, :arrete_securite, :justificatif_saturnisme]
    end

    if projet_themes.include? ("Travaux lourds") && projet.hma.nil?
      hash[:required] << :evaluation_energetique
      hash[:one_of]   << [:arrete_insalubrite_peril, :rapport_grille_insalubrite, :arrete_securite, :justificatif_saturnisme]

      if projet.invited_pris.present? && projet.hma.nil? #projet.operation.present?
        hash[:required] << :contrat_maitrise_oeuvre
        hash[:required] << :contrat_amo
      end
    end

    if projet_themes.include? ("Autres travaux") && projet.hma.nil?
      hash[:one_of] << [:notification_agence_eau, :pv_copropriete]
    end

    hash[:required] = hash[:required].uniq if hash[:required].present?
    hash[:one_of] = hash[:one_of].uniq if hash[:one_of].present?
    # Cleanup des hashs pour gérer les doublons nécessaire si on veut être robuste
    hash
  end

  private

end
