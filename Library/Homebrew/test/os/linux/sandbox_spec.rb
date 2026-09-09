# typed: true
# frozen_string_literal: true

require "sandbox"

RSpec.describe Sandbox, :needs_linux do
  describe ".with_preserved_brew_file" do
    let(:brew_directory) { HOMEBREW_PREFIX/"bin" }
    let(:brew_file) { brew_directory/"brew" }

    before do
      brew_directory.mkpath
      brew_file.write("#!/bin/sh\n")
      brew_file.chmod(0755)
    end

    it "restores the directory mode when the block changes it" do
      original_mode = brew_directory.stat.mode & 07777

      described_class.with_preserved_brew_file { brew_directory.chmod(0700) }

      expect(brew_directory.stat.mode & 07777).to eq(original_mode)
    end

    it "does not chmod the directory when the block leaves its mode alone" do
      allow(File).to receive(:open).and_wrap_original do |original, *args, &block|
        original.call(*args) do |file|
          expect(file).not_to receive(:chmod) if args.first.to_s == brew_directory.to_s
          block.call(file)
        end
      end

      described_class.with_preserved_brew_file { nil }
    end

    it "restores a replaced brew file" do
      described_class.with_preserved_brew_file { brew_file.write("#!/bin/sh\nexit 1\n") }

      expect(brew_file.read).to eq("#!/bin/sh\n")
    end
  end
end
