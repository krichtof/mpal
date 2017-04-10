require 'rails_helper'

class MonServiceContribuable
  attr_reader :adresse, :declarants, :annee_impots, :nombre_personnes_charge
  def initialize(params)
    @adresse = params[:adresse]
    @declarants = params[:declarants]
    @annee_impots = params[:annee_impots]
    @nombre_personnes_charge = params[:nombre_personnes_charge]
  end

  def retrouve_contribuable
    self
  end
end

class MonServiceAdresse
  def initialize(params)
    @latitude = params[:latitude]
    @longitude = params[:longitude]
    @departement = params[:departement]
    @ligne_1 = params[:ligne_1]
    @code_postal = params[:code_postal]
    @ville = params[:ville]
  end

  def precise(adresse)
    Adresse.new({ latitude: @latitude, longitude: @longitude, departement: @departement, ligne_1: @ligne_1, code_postal: @code_postal, ville: @ville })
  end
end

class FailingServiceAdresse
  def precise(adresse)
    nil
  end
end

describe ProjetInitializer do
  let(:service_contribuable) do
    MonServiceContribuable.new(
      adresse: "12 rue de la Mare, 75020 Paris",
      declarants: [ {prenom: 'Jean', nom: 'Martin', date_de_naissance: '19/04/1980'}],
      annee_impots: "2015",
      nombre_personnes_charge: 3,
      numero_fiscal: '15',
      reference_avis: '1515'
    )
  end
  let(:service_adresse) do
    MonServiceAdresse.new(
      latitude: "46",
      longitude: "6",
      ligne_1: "12 rue de la Mare",
      code_postal: "75020",
      code_insee: "75020",
      ville: "Paris",
      departement: "75"
    )
  end
  let(:adresse) { "12 rue de la Mare, 75020 Paris" }
  subject(:projet_initializer) do
    ProjetInitializer.new(service_contribuable, service_adresse)
  end

  describe "#initialize_projet" do
    it "renvoie un projet avec les informations du contribuable" do
      projet = projet_initializer.initialize_projet(15, 1515)
      expect(projet).to be_valid
      expect(projet.adresse.description).to eq(adresse)
      expect(projet.numero_fiscal).to eq('15')
      expect(projet.reference_avis).to eq('1515')
      expect(projet.avis_impositions.length).to eq(1)
      expect(projet.avis_impositions.first.occupants.length).to eq(4)
      expect(projet.avis_impositions.first.occupants.first).to be_declarant
    end
  end

  describe "#initialize_avis_imposition" do
    let(:projet) { create :projet }

    context "lorsque les identifiants sont valides" do
      it "crée un avis d’imposition avec les informations du contribuable" do
        expect(projet.avis_impositions.length).to eq(0)

        projet_initializer.initialize_avis_imposition(projet, '15', '1515')
        expect(projet.avis_impositions.length).to eq(1)

        avis_imposition = projet.avis_impositions.first
        expect(avis_imposition.numero_fiscal).to eq('15')
        expect(avis_imposition.reference_avis).to eq('1515')
        expect(avis_imposition.nombre_personnes_charge).to eq(3)
        expect(avis_imposition.occupants.length).to eq(4)

        occupant = avis_imposition.occupants.first
        expect(occupant).to be_declarant
        expect(occupant.nom).to eq('Martin')
      end
    end

    context "lorsque les identifiants sont invalides" do
      it "ne crée pas d'avis d'imposition" do
        expect(service_contribuable).to receive(:retrouve_contribuable).and_return(nil)
        expect(projet.avis_impositions.length).to eq(0)

        projet_initializer.initialize_avis_imposition(projet, 'INVALID', 'INVALID')
        expect(projet.avis_impositions.length).to eq(0)
      end
    end
  end

  describe "#precise_adresse" do
    context "lorsque l'adresse est disponible" do
      it "renvoie l'adresse localisée" do
        adresse_localisee = subject.precise_adresse(adresse)
        expect(adresse_localisee).to be_present
        expect(adresse_localisee.ville).to eq "Paris"
      end
    end

    context "lorsque l'adresse est indisponible" do
      let(:service_adresse) { FailingServiceAdresse.new }
      it { expect { subject.precise_adresse(adresse) }.to raise_error RuntimeError }
    end

    describe "previous_value" do
      context "lorsque l'adresse est identique à la valeur précédente" do
        let(:previous_value) { service_adresse.precise(adresse) }
        it { expect(subject.precise_adresse(adresse, previous_value: previous_value)).to equal previous_value }
      end
      context "lorsque l'adresse est différente de la valeur précédente" do
        let(:previous_value) { Adresse.new }
        it { expect(subject.precise_adresse(adresse, previous_value: previous_value)).not_to equal previous_value }
      end
    end

    describe "required" do
      let(:adresse) { nil }
      context "lorsque l'adresse est requise" do
        let(:required) { true }
        it { expect { subject.precise_adresse(adresse, required: required) }.to raise_error RuntimeError }
      end
      context "lorsque l'adresse n'est pas requise" do
        let(:required) { false }
        it { expect(subject.precise_adresse(adresse, required: required)).to be nil }
      end
    end
  end
end
