class PagesController < ApplicationController
  # GET /pages
  def index
    @pages = Page.all
    auth!
  end

  # GET /pages/1
  def show
    @page = Page.find(params[:id])
    @file_path = File.join(Rails.root, "app", "views", "pages", @page.title.parameterize + ".md")
    @markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, :autolink => true, :space_after_headers => true)
    auth!
  end

  # GET /pages/new
  def new
    @page = Page.new
    auth!
  end

  # GET /pages/1/edit
  def edit
    @page = Page.find(params[:id])
    auth!
  end

  # POST /pages
  def create
    @page = Page.new(page_params)
    auth!
    if @page.save
      redirect_to @page, :notice => 'Page was successfully created.'
    else
      render action => 'new'
    end
  end

  # PATCH/PUT /pages/1
  def update
    @page = Page.find(params[:id])
    auth!
    if @page.update(page_params)
      redirect_to @page, :notice => 'Page was successfully updated.'
    else
      render action => 'edit'
    end
  end

  # DELETE /pages/1
  def destroy
    @page = Page.find(params[:id])
    auth!
    @page.destroy
    redirect_to pages_url, :notice => 'Page was successfully destroyed.'
  end

  private
    # Only allow a trusted parameter "white list" through.
    def page_params
      params.require(:page).permit(:category, :language, :title, :body)
    end
end
