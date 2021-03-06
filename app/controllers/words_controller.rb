class WordsController < ApplicationController
  before_action :set_word, only: [:show, :edit, :update, :destroy]

  # GET /words
  # GET /words.json
  def index
    if params[:search].present?
      @words = Word.joins(:meanings).where("words.term ILIKE ? or meanings.definition ILIKE ?", "%#{params[:search]}%", "%#{params[:search]}%").uniq.paginate(page: params[:page], per_page: 4)
    else
      @words = Word.all.order("created_at DESC").paginate(page: params[:page], per_page: 10)
    end
    respond_to do |format|
      format.html
      format.csv {
        csv_data = generate_csv_data(Word.all.order("created_at ASC"), { headers: ['term','meanings','examples']}) { |word| 
          [word.term, word.meanings.collect(&:definition).join(","), word.examples.collect(&:sentence).join(",")] 
        }
        send_data csv_data
      }
    end
  end
  
  def alphabetical_order
    @words = Word.all.order("term ASC").paginate(page: params[:page], per_page: 10)
    render 'index'
  end
  # GET /words/1
  # GET /words/1.json
  def show
  end

  # GET /words/new
  def new
    @word = Word.new
  end

  # GET /words/1/edit
  def edit
  end

  # POST /words
  # POST /words.json
  def create
    @word = Word.new(word_params)

    respond_to do |format|
      if @word.save
        format.html { redirect_to words_path, notice: 'Word was successfully created.' }
        format.json { render :show, status: :created, location: @word }
      else
        format.html { render :new }
        format.json { render json: @word.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /words/1
  # PATCH/PUT /words/1.json
  def update
    respond_to do |format|
      if @word.update(word_params)
        format.html { redirect_to words_path, notice: 'Word was successfully updated.' }
        format.json { render :show, status: :ok, location: @word }
      else
        format.html { render :edit }
        format.json { render json: @word.errors, status: :unprocessable_entity }
      end
    end
  end

  def load_json
  end

  def save_json
    require 'csv'
    CSV.foreach(json_params[:attachment].path,headers: true, :header_converters => :symbol, :converters => :all) do |row|
      h = row.to_hash
      w = Word.create!(:term => h[:term])
      h[:meanings].split(",").each do |meaning|
        w.meanings.create(:definition => meaning)
      end
      if h[:examples].present?
        h[:examples].split(",").each do |example|
          w.examples.create(:sentence => example)
        end
      end
    end
  end
  # DELETE /words/1
  # DELETE /words/1.json
  def destroy
    @word.destroy
    respond_to do |format|
      format.html { redirect_to words_url, notice: 'Word was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def mapselect    
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_word
    @word = Word.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def word_params
    params.require(:word).permit(:term, meanings_attributes: [:id, :definition, :_destroy], examples_attributes: [:id, :sentence, :_destroy])
  end

  def json_params
    params.permit(:attachment)
  end
end
