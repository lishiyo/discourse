require 'spec_helper'

describe UploadsController do

  context '.create' do

    it 'requires you to be logged in' do
      -> { xhr :post, :create }.should raise_error(Discourse::NotLoggedIn)
    end

    context 'logged in' do

      before { @user = log_in :user }

      let(:logo) do
        ActionDispatch::Http::UploadedFile.new({
          filename: 'logo.png',
          tempfile: file_from_fixtures("logo.png")
        })
      end

      let(:logo_dev) do
        ActionDispatch::Http::UploadedFile.new({
          filename: 'logo-dev.png',
          tempfile: file_from_fixtures("logo-dev.png")
        })
      end

      let(:text_file) do
        ActionDispatch::Http::UploadedFile.new({
          filename: 'LICENSE.TXT',
          tempfile: File.new("#{Rails.root}/LICENSE.txt")
        })
      end

      let(:files) { [ logo_dev, logo ] }

      context 'with a file' do

        context 'when authorized' do

          before { SiteSetting.stubs(:authorized_extensions).returns(".PNG|.txt") }

          it 'is successful with an image' do
            xhr :post, :create, file: logo
            response.status.should eq 200
          end

          it 'is successful with an attachment' do
            xhr :post, :create, file: text_file
            response.status.should eq 200
          end

          context 'with a big file' do

            before { SiteSetting.stubs(:max_attachment_size_kb).returns(1) }

            it 'rejects the upload' do
              xhr :post, :create, file: text_file
              response.status.should eq 422
            end

          end

        end

        context 'when not authorized' do

          before { SiteSetting.stubs(:authorized_extensions).returns(".png") }

          it 'rejects the upload' do
            xhr :post, :create, file: text_file
            response.status.should eq 422
          end

        end

        context 'when everything is authorized' do

          before { SiteSetting.stubs(:authorized_extensions).returns("*") }

          it 'is successful with an image' do
            xhr :post, :create, file: logo
            response.status.should eq 200
          end

          it 'is successful with an attachment' do
            xhr :post, :create, file: text_file
            response.status.should eq 200
          end

        end

      end

      context 'with some files' do

        it 'is successful' do
          xhr :post, :create, files: files
          response.should be_success
        end

        it 'takes the first file' do
          xhr :post, :create, files: files
          response.body.should match /logo-dev.png/
        end

      end

    end

  end

  context '.show' do

    it "returns 404 when using external storage" do
      store = stub(internal?: false)
      Discourse.stubs(:store).returns(store)
      Upload.expects(:find_by).never
      get :show, site: "default", id: 1, sha: "1234567890abcdef", extension: "pdf"
      response.response_code.should == 404
    end

    it "returns 404 when the upload doens't exist" do
      Upload.expects(:find_by).with(id: 2, url: "/uploads/default/2/1234567890abcdef.pdf").returns(nil)
      get :show, site: "default", id: 2, sha: "1234567890abcdef", extension: "pdf"
      response.response_code.should == 404
    end

    it 'uses send_file' do
      upload = build(:upload)
      Upload.expects(:find_by).with(id: 42, url: "/uploads/default/42/66b3ed1503efc936.zip").returns(upload)

      controller.stubs(:render)
      controller.expects(:send_file)

      get :show, site: "default", id: 42, sha: "66b3ed1503efc936", extension: "zip"
    end

  end

end
